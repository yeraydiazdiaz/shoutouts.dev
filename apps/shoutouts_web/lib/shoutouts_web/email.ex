defmodule ShoutoutsWeb.Email do
  use Bamboo.Phoenix, view: ShoutoutsWeb.EmailView
  alias Shoutouts.Accounts

  @default_sender "no-reply@shoutouts.dev"

  def shoutout_digest(%Shoutouts.Accounts.User{} = user) do
    new_email(
      to: user.email,
      from: @default_sender,
      subject: "New shoutouts for your projects"
    )
    |> put_html_layout({ShoutoutsWeb.LayoutView, "email.html"})
    |> assign(:first_name, Accounts.first_name(user))
    |> assign(:user, user)
    |> render(:shoutouts_digest)
  end
end
