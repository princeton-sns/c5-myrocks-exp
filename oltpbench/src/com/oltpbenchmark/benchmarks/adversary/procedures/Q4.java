package com.oltpbenchmark.benchmarks.adversary.procedures;

import com.oltpbenchmark.api.SQLStmt;

public class Q4 extends BaseQuery {

    protected String getCallString() {
        return "{call insert004(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";
    }
}
