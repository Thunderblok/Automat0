defmodule AutomatUI.Live.Home do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, :tick)
    {:ok, assign(socket, events: [])}
  end

  def handle_info(:tick, socket) do
    snap = AutomatMetrics.snapshot()
    snap = if function_exported?(AutomatMetrics, :snapshot, 0), do: AutomatMetrics.snapshot(), else: %{}
    events = snap |> Enum.flat_map(fn {_k, v} -> Enum.reverse(v) end) |> Enum.take(50)
    {:noreply, assign(socket, events: events)}
  end

  def render(assigns) do
    ~H"""
    <main class="container">
      <h2>Automat Dashboard</h2>
      <p>Recent events (tail):</p>
      <pre style="max-height: 400px; overflow: auto; background: #111; color: #0f0; padding: 12px;">
      <%= for e <- @events do %>
        <%= Phoenix.HTML.raw(Phoenix.HTML.html_escape(Jason.encode!(e))) %>\n
      <% end %>
      </pre>
    </main>
    """
  end
end
