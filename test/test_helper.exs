ExUnit.start()

defmodule CorpcrawlTest.Helpers do
  def fixture(name) do
    {:ok, c} = File.cwd
    path = "#{c}/test/fixtures/#{name}.txt"
    File.stream!(path, [:read], :line)
  end
end