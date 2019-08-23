package com.oltpbenchmark.benchmarks.adversary;

import com.oltpbenchmark.WorkloadConfiguration;
import org.apache.commons.configuration.XMLConfiguration;

public class AdversaryConfig {

    private final XMLConfiguration xmlConfig;

    private final int terminals;

    public AdversaryConfig(WorkloadConfiguration workConf) {
        this.xmlConfig = workConf.getXmlConfig();
        this.terminals = workConf.getTerminals();
    }


    public int getTerminals() {
        return terminals;
    }

    public int getInserts() {
        return xmlConfig.getInt("inserts", 0);
    }

    public int getHotKey() {
        return xmlConfig.getInt("hotkey", 0);
    }
}
