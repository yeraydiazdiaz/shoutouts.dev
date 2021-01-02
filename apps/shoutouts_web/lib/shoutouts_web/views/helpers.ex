defmodule ShoutoutsWeb.Helpers do
  @moduledoc """
  HTML helpers
  """

  use Phoenix.HTML

  @doc """
  Returns a string with rendered colon-emojis.
  """
  def render_emojis(text) do
    text
    |> String.split
    |> Enum.reduce(
      "",
      fn word, acc ->
        if acc != "", do: "#{acc} #{convert_emoji(word)}", else: convert_emoji(word)
      end
    )
  end

  def convert_emoji(word) do
    case Regex.run(~r/:(\w+):/, word) do
      nil -> word
      [_, short_name ] -> Exmoji.from_short_name(short_name) |> Exmoji.EmojiChar.render
    end
  end
end
