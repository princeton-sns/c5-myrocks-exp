package com.oltpbenchmark.benchmarks.insert;

import com.oltpbenchmark.WorkloadConfiguration;

public class InsertConfig {

    private final int terminals;

    InsertConfig(WorkloadConfiguration workConf) {
        this.terminals = workConf.getTerminals();
    }

    public int getTerminals() {
        return terminals;
    }
}
