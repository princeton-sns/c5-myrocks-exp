package com.oltpbenchmark.benchmarks.insert.procedures;

public class PointRead extends InsertProcedure {

    protected String getCallString() {
        return "{call pointread(?, ?)}";
    }
}
