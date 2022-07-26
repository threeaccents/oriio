defmodule Oriio.Transformations.Transformer do
  @moduledoc """
  Uses LibVips to handle file transformations.
  """

  alias Vix.Vips.Image
  alias Vix.Vips.Operation

  @type angle() :: 90 | 180 | 270

  # make less generic in the future.
  @type format() :: String.t()

  @type transformations() :: %{
          width: integer(),
          height: integer(),
          black_n_white: boolean(),
          crop: boolean(),
          flip: boolean(),
          rotate: angle(),
          format: format()
        }

  @type document_path() :: binary()

  @spec transform_file(document_path, transformations()) ::
          {:ok, document_path} | {:error, term()}
  def transform_file(document_path, transformations) do
    case Image.new_from_file(document_path) do
      {:ok, vips_image} ->
        image = transform(vips_image, transformations, &apply_transform/4)

        dir = Briefly.create!(directory: true)
        document_path = Path.join(dir, file_name(document_path, transformations.format))

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


  defp apply_transform(image, :width, width, _transformations) do
    current_width = Image.width(image)
    hscale = width / current_width
    Operation.resize!(image, hscale)
  end

  defp apply_transform(image, :height, height, _transformations) do
    current_height = Image.height(image)

    vscale = height / current_height

    # since we are mainting aspect ration we can just pass the vscale as the hscale for resize
    Operation.resize!(image, vscale)
  end

  defp apply_transform(image, :black_n_white, true, _transformations) do
    Operation.colourspace!(image, :VIPS_INTERPRETATION_B_W)
  end

  defp apply_transform(image, :flip, true, _transformations) do
    Operation.flip(image, :VIPS_DIRECTION_HORIZONTAL)
  end

  defp apply_transform(image, :flop, true, _transformations) do
    Operation.flip(image, :VIPS_DIRECTION_VERTICAL)
  end

  defp apply_transform(image, :rotate, 90, _transformations) do
    Operation.rot(image, :VIPS_ANGLE_D90)
  end

  defp apply_transform(image, :rotate, 180, _transformations) do
    Operation.rot(image, :VIPS_ANGLE_D180)
  end

  defp apply_transform(image, :rotate, 270, _transformations) do
    Operation.rot(image, :VIPS_ANGLE_D270)
  end

  defp apply_transform(image, _, _, _), do: image

  defp file_name(document_path, nil) do
    document_path
    |> String.split("/")
    |> List.last()
  end

  defp file_name(document_path, extension) do
    name =
      document_path
      |> String.split("/")
      |> List.last()

    [name_no_ext | _] = String.split(name, ".")

    "#{name_no_ext}.#{extension}"
  end
end
