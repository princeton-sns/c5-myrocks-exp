package com.oltpbenchmark.benchmarks.adversary.procedures;

import java.util.List;
import java.util.Random;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.CallableStatement;

import org.apache.commons.lang.RandomStringUtils;
import org.apache.log4j.Logger;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;

public abstract class BaseQuery extends Procedure {

    private static final Logger LOG = Logger.getLogger(BaseQuery.class);

    private static final Random random = new Random();

    // Txn
    private CallableStatement storedProc = null;

    protected abstract String getCallString();

    public void run(Connection conn, int hotKey, List<Integer> keys) throws SQLException {
        if (storedProc == null) {
            storedProc = conn.prepareCall(getCallString());
        }

        int i = 0;
        storedProc.setInt(++i, hotKey);
        storedProc.setInt(++i, random.nextInt());

        for (Integer k : keys) {
            storedProc.setInt(++i, k);
            storedProc.setInt(++i, k);
            storedProc.setInt(++i, random.nextInt());
        }

        storedProc.execute();
    }

}
