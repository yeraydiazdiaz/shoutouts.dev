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
    |> String.split()
    |> Enum.reduce(
      "",
      fn word, acc ->
        if acc != "", do: "#{acc} #{convert_emoji(word)}", else: convert_emoji(word)
      end
    )
  end

  def convert_emoji(word) do
    with [_, short_name] <- Regex.run(~r/:(\w+):/, word),
         emoji_char when emoji_char != nil <- Exmoji.from_short_name(short_name) do
      Exmoji.EmojiChar.render(emoji_char)
    else
      _ -> word
    end
  end
end
