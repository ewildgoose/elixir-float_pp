defmodule FloatPPTest do
  use ExUnit.Case, async: true
  doctest FloatPP

  test "Simple float test" do
    assert "1.2" ==
            FloatPP.to_string(1.2)
  end

  test "small float" do
    assert "0.000001" ==
            FloatPP.to_string(0.000001)
  end

  test "small negative float" do
    assert "-0.000001" ==
            FloatPP.to_string(-0.000001)
  end

  test "large float test" do
    assert "10000.0" ==
            FloatPP.to_string(10000.0)
  end

  ############################################################################

  test "round using rounding: :down" do
    options = %{rounding: :down, decimals: 0, compact: true}

    assert "11.0", FloatPP.to_string(11.4, options)
    assert "11.0", FloatPP.to_string(11.5, options)
    assert "11.0", FloatPP.to_string(11.6, options)
    assert "12.0", FloatPP.to_string(12.5, options)
    assert "-11.0", FloatPP.to_string(-11.4, options)
    assert "-11.0", FloatPP.to_string(-11.5, options)
    assert "-11.0", FloatPP.to_string(-11.6, options)
    assert "-12.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :up" do
    options = %{rounding: :half_down, decimals: 0, compact: true}

    assert "12.0", FloatPP.to_string(11.4, options)
    assert "12.0", FloatPP.to_string(11.5, options)
    assert "12.0", FloatPP.to_string(11.6, options)
    assert "13.0", FloatPP.to_string(12.5, options)
    assert "-12.0", FloatPP.to_string(-11.4, options)
    assert "-12.0", FloatPP.to_string(-11.5, options)
    assert "-12.0", FloatPP.to_string(-11.6, options)
    assert "-13.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :half_up" do
    options = %{rounding: :half_up, decimals: 0, compact: true}

    assert "11.0", FloatPP.to_string(11.4, options)
    assert "12.0", FloatPP.to_string(11.5, options)
    assert "12.0", FloatPP.to_string(11.6, options)
    assert "13.0", FloatPP.to_string(12.5, options)
    assert "-11.0", FloatPP.to_string(-11.4, options)
    assert "-12.0", FloatPP.to_string(-11.5, options)
    assert "-12.0", FloatPP.to_string(-11.6, options)
    assert "-13.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :half_even" do
    options = %{rounding: :half_even, decimals: 0, compact: true}

    assert "11.0", FloatPP.to_string(11.4, options)
    assert "12.0", FloatPP.to_string(11.5, options)
    assert "12.0", FloatPP.to_string(11.6, options)
    assert "12.0", FloatPP.to_string(12.5, options)
    assert "-11.0", FloatPP.to_string(-11.4, options)
    assert "-12.0", FloatPP.to_string(-11.5, options)
    assert "-12.0", FloatPP.to_string(-11.6, options)
    assert "-12.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :half_down" do
    options = %{rounding: :half_down, decimals: 0, compact: true}

    assert "11.0", FloatPP.to_string(11.4, options)
    assert "11.0", FloatPP.to_string(11.5, options)
    assert "12.0", FloatPP.to_string(11.6, options)
    assert "12.0", FloatPP.to_string(12.5, options)
    assert "-11.0", FloatPP.to_string(-11.4, options)
    assert "-11.0", FloatPP.to_string(-11.5, options)
    assert "-12.0", FloatPP.to_string(-11.6, options)
    assert "-12.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :ceiling" do
    options = %{rounding: :ceiling, decimals: 0, compact: true}

    assert "12.0", FloatPP.to_string(11.4, options)
    assert "12.0", FloatPP.to_string(11.5, options)
    assert "12.0", FloatPP.to_string(11.6, options)
    assert "13.0", FloatPP.to_string(12.5, options)
    assert "-11.0", FloatPP.to_string(-11.4, options)
    assert "-11.0", FloatPP.to_string(-11.5, options)
    assert "-11.0", FloatPP.to_string(-11.6, options)
    assert "-12.0", FloatPP.to_string(-12.5, options)
  end

  test "round using rounding: :floor" do
    options = %{rounding: :floor, decimals: 0, compact: true}

    assert "11.0", FloatPP.to_string(11.4, options)
    assert "11.0", FloatPP.to_string(11.5, options)
    assert "11.0", FloatPP.to_string(11.6, options)
    assert "12.0", FloatPP.to_string(12.5, options)
    assert "-12.0", FloatPP.to_string(-11.4, options)
    assert "-12.0", FloatPP.to_string(-11.5, options)
    assert "-12.0", FloatPP.to_string(-11.6, options)
    assert "-13.0", FloatPP.to_string(-12.5, options)
  end

  test "cascading rounding" do
    options = %{rounding: :ceiling, decimals: 0, compact: true}

    assert "2.0" == FloatPP.to_string(1.9999, options)
    assert "10.0" == FloatPP.to_string(9.9999, options)
    assert "1000.0" == FloatPP.to_string(999.9999, options)
  end


  ############################################################################


  test "test to_digits(zero)" do
    assert "0.0" == FloatPP.to_string(0.0)
  end

  test "test to_digits(one)" do
    assert "1.0" == FloatPP.to_string(1.0)
  end

  test "test to_digits(negative one)" do
    assert "-1.0" == FloatPP.to_string(-1.0)
  end

  test "test to_digits(small denormalized number)" do
    # 4.94065645841246544177e-324
    <<small_denorm::float>> = <<0,0,0,0,0,0,0,1>>
    assert "4.9406564584124654e-324" == FloatPP.to_string(small_denorm, %{scientific: true, compact: true})
  end

  test "test to_digits(large denormalized number)" do
    # 2.22507385850720088902e-308
    <<large_denorm::float>> = <<0,15,255,255,255,255,255,255>>
    assert "2.225073858507201e-308" == FloatPP.to_string(large_denorm, %{scientific: true, compact: true})
  end

  test "test to_digits(small normalized number)" do
    # 2.22507385850720138309e-308
    <<small_norm::float>> = <<0,16,0,0,0,0,0,0>>
    assert "2.2250738585072014e-308" == FloatPP.to_string(small_norm, %{scientific: true, compact: true})
  end

  test "test to_digits(large normalized number)" do
    # 1.79769313486231570815e+308
    <<large_norm::float>> = <<127,239,255,255,255,255,255,255>>
    assert "1.7976931348623157e+308" == FloatPP.to_string(large_norm, %{scientific: true, compact: true})
  end


  ############################################################################


  test "test format_decimal scientific" do
    assert  "7.00000000000000000000e+00" =
            FloatPP.format_decimal({["7"], 1, true}, %{scientific: 20, compact: false}) |> IO.iodata_to_binary

    assert  "7.0e+00" =
            FloatPP.format_decimal({["7"], 1, true}, %{scientific: 20, compact: true}) |> IO.iodata_to_binary

    assert  "7.0e+01" =
            FloatPP.format_decimal({["7"], 2, true}, %{scientific: 20, compact: true}) |> IO.iodata_to_binary

    assert  "7.0e-02" =
            FloatPP.format_decimal({["7"], -1, true}, %{scientific: 20, compact: true}) |> IO.iodata_to_binary

    assert  "7.0e-10" =
            FloatPP.format_decimal({["7"], -9, true}, %{scientific: 20, compact: true}) |> IO.iodata_to_binary
  end

  test "test format_decimal decimal" do
    assert  "7.00000000000000000000" =
            FloatPP.format_decimal({["7"], 1, true}, %{decimals: 20, compact: false}) |> IO.iodata_to_binary

    assert  "7.0" =
            FloatPP.format_decimal({["7"], 1, true}, %{decimals: 20, compact: true}) |> IO.iodata_to_binary

    assert  "70.0" =
            FloatPP.format_decimal({["7"], 2, true}, %{decimals: 20, compact: true}) |> IO.iodata_to_binary

    assert  "0.07" =
            FloatPP.format_decimal({["7"], -1, true}, %{decimals: 20, compact: true}) |> IO.iodata_to_binary

    assert  "0.0000000007" =
            FloatPP.format_decimal({["7"], -9, true}, %{decimals: 20, compact: true}) |> IO.iodata_to_binary
  end


end
