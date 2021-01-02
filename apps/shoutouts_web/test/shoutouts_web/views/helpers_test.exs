defmodule ShoutoutsWeb.HelpersTest do
  use ShoutoutsWeb.ConnCase, async: true
  alias ShoutoutsWeb.Helpers

  test "returns same string if no colon emojis" do
    assert Helpers.render_emojis("no emojis here") == "no emojis here"
  end

  test "replaces one colon emoji with no other text" do
    assert Helpers.render_emojis(":smile:") == "😄"
  end

  test "replaces several emojis" do
    assert Helpers.render_emojis(":smile: colon-emojis are :tada:") == "😄 colon-emojis are 🎉"
  end

  test "trims leading and trailing whitespace" do
    assert Helpers.render_emojis(" << space here :skull: space here >> ") == "<< space here 💀 space here >>"
  end

  test "returns the colon substring if no such emoji exists" do
    assert Helpers.render_emojis(":foobar: aint no emoji") == ":foobar: aint no emoji"
  end
end
