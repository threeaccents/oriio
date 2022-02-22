defmodule Mahi.Transformations.Transformer do
  # alias Mahi.Files.FileModel
  # alias Vix.Vips

  # @type transformations() :: %{
  #         width: integer(),
  #         height: integer(),
  #         black_n_white: boolean(),
  #         crop: boolean(),
  #         format: String.t(),
  #         extension: String.t()
  #       }

  # @spec transform_file(FileModel.t(), transformations()) ::
  #         {:ok, FileModel.t()} | {:error, term()}
  # def transform_file(file_model, transformations) do
  #   case Vips.Image.new_from_file(file_model.file_path) do
  #     {:ok, vips_image} ->
  #       image = transform(vips_image, transformations, &apply_transform/4)

  #       {:ok, path} = Briefly.create(directory: true)
  #       final_path = Path.join(path, file_model.file_name)
  #       :ok = Vips.Image.write_to_file(image, final_path)

  #       {:ok, %FileModel{file_model | file_path: final_path}}

  #     {:error, reason} ->
  #       {:error, reason}
  #   end
  # end

  # defp transform(image, transformations, apply_transform) do
  #   Enum.reduce(transformations, image, fn {key, value}, img ->
  #     apply_transform.(img, key, value, transformations)
  #   end)
  # end

  # defp apply_transform(image, :crop, true, %{width: _width, height: _height}) do
  #   image
  # end

  # defp apply_transform(image, transformation, value, _transformations) do
  #   apply_transform(image, transformation, value)
  # end

  # defp apply_transform(image, :width, width) do
  #   current_width = Vips.Image.width(image)
  #   hscale = width / current_width
  #   Vips.Operation.resize!(image, hscale)
  # end

  # defp apply_transform(image, :height, height) do
  #   current_height = Vips.Image.height(image)

  #   vscale = height / current_height

  #   # since we are mainting aspect ration we can just pass the vscale as the hscale for resize
  #   Vips.Operation.resize!(image, vscale)
  # end

  # defp apply_transform(image, :black_n_white, true) do
  #   Vips.Operation.colourspace!(image, :VIPS_INTERPRETATION_B_W)
  # end

  # defp apply_transform(image, _, _), do: image
end
