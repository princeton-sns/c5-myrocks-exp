package com.oltpbenchmark.benchmarks.insert.procedures;

public class Insert2 extends InsertProcedure {

    protected String getCallString() {
        return "{call insertsp002(?, ?, ?, ?)}";
    }
}
