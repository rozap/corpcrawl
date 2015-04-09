defmodule Corpcrawl.Main do

  alias Corpcrawl.Model.Filing
  alias Corpcrawl.Model.Subsidiary



  defp process_form(downloader) do
    case Edgarex.FTP.Pool.checkout(downloader, 1) do
      :not_downloading -> :ok
      [] -> 
        :timer.sleep(1000)
        process_form(downloader)
      forms ->

        forms
        |> Corpcrawl.load_forms
        |> Enum.map(fn {filing, subs} ->
          IO.puts "Company: #{inspect filing} #{inspect subs}"
          Enum.map(subs, fn s -> 
            try do
              Subsidiary.create(filing, s) 
            rescue
              e -> IO.inspect "Failed for sub #{inspect s} with #{inspect e}"
            end
          end)
        end)

        process_form(downloader)
    end
  end


  defp run_selection({[quarter: quarter, year: year], _, _}) do
    {:ok, downloader} = Edgarex.FTP.Pool.start_link()
    filings = Corpcrawl.get_10ks(year, quarter)|> Enum.drop(5) |> Filing.insert_many

    Edgarex.FTP.Pool.download(downloader, filings)
    process_form(downloader)
  end



  defp strict, do: [quarter: :integer, year: :integer]
  defp aliases, do: [q: :quarter, y: :year]
  def main(args) do
    Corpcrawl.Repo.start_link

    OptionParser.parse(args, strict: strict, aliases: aliases)
    |> run_selection
  end
end