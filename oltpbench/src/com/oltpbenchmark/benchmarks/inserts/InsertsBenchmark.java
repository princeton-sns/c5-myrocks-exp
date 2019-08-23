package com.oltpbenchmark.benchmarks.inserts;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.oltpbenchmark.WorkloadConfiguration;
import com.oltpbenchmark.api.BenchmarkModule;
import com.oltpbenchmark.api.Loader;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.inserts.procedures.Inserts;

public class InsertsBenchmark extends BenchmarkModule {

    private final InsertsConfig config;

    public InsertsBenchmark(WorkloadConfiguration workConf) {
        super("inserts", workConf, true);
        this.config = new InsertsConfig(workConf);
    }

    @Override
    protected List<Worker<? extends BenchmarkModule>> makeWorkersImpl(boolean verbose) throws IOException {
        List<Worker<? extends BenchmarkModule>> workers = new ArrayList<Worker<? extends BenchmarkModule>>();
        int hotKey = 0;
        int n = this.config.getTerminals();
        for (int i = 0; i < n; ++i) {
            workers.add(new InsertsWorker(this, config, i));
        }

        return workers;
    }

    @Override
    protected Loader<InsertsBenchmark> makeLoaderImpl(Connection conn) throws SQLException {
        return new InsertsLoader(this, conn);
    }

    @Override
    protected Package getProcedurePackageImpl() {
        return Inserts.class.getPackage();
    }

}
