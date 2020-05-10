package com.oltpbenchmark.benchmarks.insert.procedures;

public class Insert1 extends InsertProcedure {

    protected String getCallString() {
        return "{call insertsp001(?, ?)}";
    }
}
