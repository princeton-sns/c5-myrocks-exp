package com.oltpbenchmark.benchmarks.inserts;

import com.oltpbenchmark.api.Loader;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

public class InsertsLoader extends Loader<InsertsBenchmark> {

    InsertsLoader(InsertsBenchmark benchmark, Connection c) {
        super(benchmark, c);
    }
    
    @Override
    public List<LoaderThread> createLoaderThreads() throws SQLException {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public void load() throws SQLException {
    }
}
