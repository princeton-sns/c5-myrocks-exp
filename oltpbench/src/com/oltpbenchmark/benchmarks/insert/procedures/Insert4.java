package com.oltpbenchmark.benchmarks.insert.procedures;

public class Insert4 extends InsertProcedure {

    protected String getCallString() {
        return "{call insertsp004(?, ?, ?, ?, ?, ?, ?, ?)}";
    }
}
