package com.oltpbenchmark.benchmarks.insert;

import com.oltpbenchmark.WorkloadConfiguration;
import org.apache.commons.configuration.XMLConfiguration;

public class InsertConfig {

    private final XMLConfiguration xmlConfig;

    private final int terminals;

    InsertConfig(WorkloadConfiguration workConf) {
        this.xmlConfig = workConf.getXmlConfig();
        this.terminals = workConf.getTerminals();
    }

    public int getTerminals() {
        return terminals;
    }

    public int getInsertsPerTransaction() {
        return xmlConfig.getInt("insertspertransaction", 1);
    }
}
