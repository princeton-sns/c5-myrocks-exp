package com.oltpbenchmark.benchmarks.insert;

import com.oltpbenchmark.api.Loader;

import java.sql.PreparedStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

public class InsertLoader extends Loader<InsertBenchmark> {

    InsertLoader(InsertBenchmark benchmark, Connection c) {
        super(benchmark, c);
    }
    
    @Override
    public List<LoaderThread> createLoaderThreads() throws SQLException {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public void load() throws SQLException {
	PreparedStatement insert = this.conn.prepareStatement("INSERT INTO KV (K, V) VALUES (?, ?)");

	insert.setInt(1, -1);
	insert.setInt(2, -1);

	insert.execute();

	this.conn.commit();
    }
}
