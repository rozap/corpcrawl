defmodule Corpcrawl.Main do

  defp on_batch(results) do
    Enum.map(results, fn {form_10k, subs} ->
      IO.puts "company: #{form_10k.company_name} #{form_10k.cik} #{form_10k.file_name}"
      Enum.each(subs, fn s -> IO.puts("    - #{inspect s}") end)
    end)
  end

  defp run_batch(ten_ks, batch_size, concurrency) do
    ten_ks
    |> Enum.take(batch_size)
    |> Corpcrawl.ten_k_to_subs(concurrency)
    |> on_batch

    ten_ks
    |> Enum.drop(batch_size)
    |> run_batch(batch_size, concurrency)

  end

  defp run_selection({[quarter: quarter, year: year, concurrency: concurrency, batch_size: batch_size], _, _}) do
    Corpcrawl.get_10ks(year, quarter)
    |> run_batch(batch_size, concurrency)
  end



  defp strict, do: [quarter: :integer, year: :integer, concurrency: :integer, batch_size: :integer]
  defp aliases, do: [q: :quarter, y: :year, c: :concurrency, b: :batch_size]
  def main(args) do
    OptionParser.parse(args, strict: strict, aliases: aliases)
    |> run_selection
    end
end