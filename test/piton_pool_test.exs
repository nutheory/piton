defmodule PitonPoolTest do
  use ExUnit.Case

  test "1 call to the Pool (Calls < Pool)" do
    IO.puts("Running test: 1 call to the Pool (Calls < Pool) ...")
    {:ok, pool} = Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: 2], [])
    result = Piton.Pool.execute(pool, :fib, [35])
    assert(result == {:ok, 9_227_465})
  end

  test "2 calls to the Pool (Calls == Pool)" do
    IO.puts("Running test: 2 calls to the Pool (Calls == Pool) ...")
    {:ok, pool} = Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: 2], [])

    result =
      for(i <- 1..2, do: i)
      |> Enum.map(fn _ -> Task.async(fn -> Piton.Pool.execute(pool, :fib, [35], 60000) end) end)
      |> Enum.map(fn task -> Task.await(task) end)

    assert(result == [{:ok, 9_227_465}, {:ok, 9_227_465}])
  end

  test "6 calls to the Pool (Calls > Pool)" do
    IO.puts("Running test: 6 calls to the Pool (Calls > Pool) ...")
    {:ok, pool} = Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: 2], [])
    timeout = 50000

    result =
      for(i <- 1..10, do: i)
      |> Enum.map(fn _ -> Task.async(fn -> Piton.Pool.execute(pool, :fib, [35], timeout) end) end)
      |> Enum.map(fn task -> Task.await(task, timeout) end)

    assert(
      result == [
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465}
      ]
    )
  end

  test "Raising a python exception" do
    IO.puts("Running test: Raising a python exception ...")
    {:ok, pool} = Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: 2], [])
    result = Piton.Pool.execute(pool, :fib, [-1])
    assert(elem(result, 0) == :error)
  end

  test "Break all the ports" do
    IO.puts("Running test: Break all the ports ...")
    pool_number = 2
    timeout = 50000

    {:ok, pool} =
      Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: pool_number], [])

    for(i <- 1..pool_number, do: i)
    |> Enum.map(fn _ -> Task.async(fn -> Piton.Pool.execute(pool, :fib, [-1], timeout) end) end)
    |> Enum.map(fn task -> Task.await(task, timeout) end)

    Process.sleep(10)
    assert(Piton.Pool.get_number_of_available_ports(pool) == pool_number)
  end

  test "Same exceptions as the number of pythons and some valid operations after" do
    IO.puts(
      "Running test: Same exceptions as the number of pythons and some valid operations after ..."
    )

    pool_number = 2
    timeout = 50000

    {:ok, pool} =
      Piton.Pool.start_link([module: MyPythonFibCalculator, pool_number: pool_number], [])

    for(i <- 1..pool_number, do: i)
    |> Enum.map(fn _ -> Task.async(fn -> Piton.Pool.execute(pool, :fib, [-1], timeout) end) end)
    |> Enum.map(fn task -> Task.await(task, timeout) end)

    result =
      for(i <- 1..10, do: i)
      |> Enum.map(fn _ -> Task.async(fn -> Piton.Pool.execute(pool, :fib, [35], timeout) end) end)
      |> Enum.map(fn task -> Task.await(task, timeout) end)

    assert(
      result == [
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465},
        {:ok, 9_227_465}
      ]
    )
  end
end
