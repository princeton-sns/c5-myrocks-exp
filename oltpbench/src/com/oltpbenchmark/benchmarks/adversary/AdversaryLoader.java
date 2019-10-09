package com.oltpbenchmark.benchmarks.adversary;

import java.sql.PreparedStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

import org.apache.log4j.Logger;

import com.oltpbenchmark.api.Loader;

public class AdversaryLoader extends Loader<AdversaryBenchmark> {
    private static final Logger LOG = Logger.getLogger(AdversaryLoader.class);

    public AdversaryLoader(AdversaryBenchmark benchmark, Connection c) {
        super(benchmark, c);
    }

    @Override
    public List<LoaderThread> createLoaderThreads() throws SQLException {
        return null;
    }

    @Override
    public void load() throws SQLException {
        PreparedStatement insert = this.conn.prepareStatement("INSERT INTO HOTKEY (K, V) VALUES (?, ?)");

        insert.setInt(1, 0);
        insert.setInt(2, 0);

        insert.execute();

	this.conn.commit();
    }
}
