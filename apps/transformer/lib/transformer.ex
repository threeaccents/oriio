defmodule Transformer do
  @moduledoc """
  Uses LibVips to handle file transformations.
  """

  alias Transformer.Transformations

  alias Vix.Vips.Image as: VipsImage
  alias Vix.Vips.Operation

  @type file_path() :: binary()

  @spec transform_file(file_path, Transformations.t()) :: {:ok, file_path()} | {:error, term()}
  def transform_file(file_path, %Transformations{} = transformations) do
    with {:ok, vips_image} <- VipsImage.new_from_file(file_path),
         {:ok, image} <- transform(vips_image, transformations),
         :ok <- write_image_to_file(image, file_path, transformations.format) do
      {:ok, file_path}
    end
  end

  defp write_image_to_file(transformed_image, file_path, format) do
    dir = Briefly.create!(directory: true)

    file_path = Path.join(dir, file_name(file_path, transformations.format))

    VipsImage.write_to_file(transformed_image, file_path)
  end

  defp transform(%VipsImage{} = image, %Transformations{} = transformations) do
    case apply_transformations(image, transformations) do
      %{image: image, errors: []} ->
        {:ok, image}

      %{errors: errors} ->
        {:error, inspect(errors)}
    end
  end

  defp apply_transformations(image, transformations) do
    initial_state = %{image: image, errors: []}

    for {transformation, value} <- transformations, reduce: initial_state do
      acc ->
        case apply_transformation(%VipsImage{} = image, transformation, value) do
          {:ok, image} ->
            Map.put(acc, :image, image)

          {:error, reason} ->
            updated_errors = [reason | acc.errors]
            Map.put(acc, :errors, updated_errors)
        end
    end
  end

  defp file_name(file_path, nil) do
    file_path
    |> String.split("/")
    |> List.last()
  end

  defp file_name(file_path, extension) do
    name =
      file_path
      |> String.split("/")
      |> List.last()

    [name_no_ext | _] = String.split(name, ".")

    "#{name_no_ext}.#{extension}"
  end

  defp apply_transformation(%VipsImage{} = image, :width, width) when is_integer(width) do
    height = Image.height(image)

    Image.thumbnail(image, "#{width}x#{height}")
  end

  defp apply_transformation(%VipsImage{} = image, :height, height) when is_integer(height) do
    width = Image.width(image)

    Image.thumbnail(image, "#{width}x#{height}")
  end

  defp apply_transformation(%VipsImage{} = image, :black_n_white, true) do
    Image.to_colorspace(image, :bw)
  end

  defp apply_transformation(%VipsImage{} = image, :flip, direction) when direction in ["vertical", "horizontal"] do
    Image.flip(image, String.to_atom(direction))
  end

  defp apply_transformation(%VipsImage{} = image, :rotate, angle) when is_float(angle) do
    Image.rotate(image, angle)
  end

  defp apply_transformation(_image, transformation, value),
    do: {:error, "Invalid value passed for #{Atom.to_string(transformation)}: #{value}"}
end
