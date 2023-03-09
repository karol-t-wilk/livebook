defmodule LivebookWeb.Hub.SecretFormComponent do
  use LivebookWeb, :live_component

  alias Livebook.Hubs
  alias Livebook.Secrets
  alias Livebook.Secrets.Secret

  @impl true
  def update(assigns, socket) do
    changeset =
      Secrets.change_secret(%Secret{}, %{
        name: assigns.secret_name,
        value: assigns.secret_value
      })

    socket = assign(socket, assigns)

    {:ok, assign(socket, title: title(socket), changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl flex flex-col space-y-5">
      <h3 class="text-2xl font-semibold text-gray-800">
        <%= @title %>
      </h3>
      <div class="flex flex-columns gap-4">
        <.form
          :let={f}
          id={"#{@id}-form"}
          for={@changeset}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          autocomplete="off"
          class="basis-1/2 grow"
        >
          <div class="flex flex-col space-y-4">
            <.text_field
              field={f[:name]}
              label="Name (alphanumeric and underscore)"
              autofocus={@secret_name == nil}
              spellcheck="false"
              autocomplete="off"
              phx-debounce="blur"
              class="uppercase"
            />
            <.text_field
              field={f[:value]}
              label="Value"
              autofocus={@secret_name != nil}
              spellcheck="false"
              autocomplete="off"
              phx-debounce="blur"
            />
            <.hidden_field field={f[:hub_id]} value={@hub.id} />
            <div class="flex space-x-2">
              <button class="button-base button-blue" type="submit" disabled={not @changeset.valid?}>
                <.remix_icon icon="add-line" class="align-middle" />
                <span class="font-normal">Add</span>
              </button>
              <.link patch={@return_to} class="button-base button-outlined-gray">
                Cancel
              </.link>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"secret" => attrs}, socket) do
    with {:ok, secret} <- Secrets.update_secret(%Secret{}, attrs),
         :ok <- set_secret(socket, secret) do
      {:noreply, push_patch(socket, to: socket.assigns.return_to)}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"secret" => attrs}, socket) do
    changeset =
      %Secret{}
      |> Secrets.change_secret(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp title(%{assigns: %{secret_name: nil}}), do: "Add secret"
  defp title(_), do: "Edit secret"

  defp set_secret(%{assigns: %{secret_name: nil}} = socket, %Secret{} = secret) do
    Hubs.create_secret(socket.assigns.hub, secret)
  end

  defp set_secret(socket, %Secret{} = secret) do
    Hubs.update_secret(socket.assigns.hub, secret)
  end
end
