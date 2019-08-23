package com.oltpbenchmark.benchmarks.inserts;

import com.oltpbenchmark.WorkloadConfiguration;

public class InsertsConfig {

    private final int terminals;

    InsertsConfig(WorkloadConfiguration workConf) {
        this.terminals = workConf.getTerminals();
    }

    public int getTerminals() {
        return terminals;
    }
}
