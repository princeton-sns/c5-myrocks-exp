package com.oltpbenchmark.benchmarks.insert;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.oltpbenchmark.WorkloadConfiguration;
import com.oltpbenchmark.api.BenchmarkModule;
import com.oltpbenchmark.api.Loader;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.insert.procedures.InsertProcedure;

public class InsertBenchmark extends BenchmarkModule {

    private final InsertConfig config;

    public InsertBenchmark(WorkloadConfiguration workConf) {
        super("insert", workConf, true);
        this.config = new InsertConfig(workConf);
    }

    @Override
    protected List<Worker<? extends BenchmarkModule>> makeWorkersImpl(boolean verbose) throws IOException {
        List<Worker<? extends BenchmarkModule>> workers = new ArrayList<Worker<? extends BenchmarkModule>>();
        int n = this.config.getTerminals();
        for (int i = 0; i < n; ++i) {
            workers.add(new InsertWorker(this, config, i));
        }

        return workers;
    }

    @Override
    protected Loader<InsertBenchmark> makeLoaderImpl(Connection conn) throws SQLException {
        return new InsertLoader(this, conn);
    }

    @Override
    protected Package getProcedurePackageImpl() {
        return InsertProcedure.class.getPackage();
    }

}
