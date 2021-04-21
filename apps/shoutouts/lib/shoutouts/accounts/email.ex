defmodule Shoutouts.Accounts.Email do
  import Bamboo.Email
  alias Shoutouts.Accounts

  @default_sender "no-reply@shoutouts.dev"
  @path Path.dirname(__ENV__.file)

  def shoutout_digest(%Shoutouts.Accounts.User{} = user) do
    new_email(
      to: user.email,
      from: @default_sender,
      subject: "New shoutouts for your projects",
      text_body:
        EEx.eval_file(Path.join(@path, "shoutout_digest.eex"),
          first_name: Accounts.first_name(user)
        )
    )
  end
end
