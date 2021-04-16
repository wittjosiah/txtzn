defmodule TxtznWeb.Components.SignInForm do
  @moduledoc """
  Documentation for `TxtznWeb.SigninForm`
  """

  use TxtznWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <Form for={{ :sign_in }} action="/signin" method="POST">
      <Field class="flex flex-col mb-8" name="user_id">
        <Label class="text-sm font-bold pb-1">Your UserID</Label>
        <TextInput class="p-2 border border-gray-300" field={{ :user_id }}/>
      </Field>
      <Field class="flex flex-col mb-8" name="password">
        <Label class="text-sm font-bold pb-1"/>
        <PasswordInput class="p-2 border border-gray-300" field={{ :password }}/>
      </Field>
      <Button full={{ true }} kind="primary" type="submit">
        Sign In
      </Button>
    </Form>
    """
  end
end
