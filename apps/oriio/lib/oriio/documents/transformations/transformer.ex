defmodule Oriio.Transformations.Transformer do
  @moduledoc """
  Uses LibVips to handle file transformations.
  """

  alias Vix.Vips.Image
  alias Vix.Vips.Operation

  @type transformations() :: %{
          width: integer(),
          height: integer(),
          black_n_white: boolean(),
          crop: boolean(),
          format: binary(),
          extension: binary()
        }

  @type document_path() :: binary()

  @spec transform_file(document_path, transformations()) ::
          {:ok, document_path} | {:error, term()}
  def transform_file(document_path, transformations) do
    case Image.new_from_file(document_path) do
      {:ok, vips_image} ->
        image = transform(vips_image, transformations, &apply_transform/4)

        dir = Briefly.create!(directory: true)
        document_path = Path.join(dir, file_name(document_path))

        :ok = Image.write_to_file(image, document_path)

        {:ok, document_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp transform(image, transformations, apply_transform) do
    Enum.reduce(transformations, image, fn {key, value}, img ->
      apply_transform.(img, key, value, transformations)
    end)
  end

  defp apply_transform(image, :crop, true, %{width: _width, height: _height}) do
    image
  end

  defp apply_transform(image, transformation, value, _transformations) do
    apply_transform(image, transformation, value)
  end

  defp apply_transform(image, :width, width) do
    current_width = Image.width(image)
    hscale = width / current_width
    Operation.resize!(image, hscale)
  end

  defp apply_transform(image, :height, height) do
    current_height = Image.height(image)

    vscale = height / current_height

    # since we are mainting aspect ration we can just pass the vscale as the hscale for resize
    Operation.resize!(image, vscale)
  end

  defp apply_transform(image, :black_n_white, true) do
    Operation.colourspace!(image, :VIPS_INTERPRETATION_B_W)
  end

  defp apply_transform(image, _, _), do: image

  defp file_name(document_path) do
    document_path
    |> String.split("/")
    |> List.last()
  end
end
