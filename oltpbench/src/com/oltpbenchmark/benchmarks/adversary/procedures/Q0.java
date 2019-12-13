package com.oltpbenchmark.benchmarks.adversary.procedures;

import com.oltpbenchmark.api.SQLStmt;

public class Q0 extends BaseQuery {
    protected String getCallString() {
        return "{call insert000(?, ?)}";
    }
}
