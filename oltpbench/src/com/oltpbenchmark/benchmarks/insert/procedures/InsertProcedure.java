package com.oltpbenchmark.benchmarks.insert.procedures;

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

public abstract class InsertProcedure extends Procedure {

    private static final Logger LOG = Logger.getLogger(InsertProcedure.class);

    // Txn
    private CallableStatement storedProc = null;

    protected abstract String getCallString();

    public void run(Connection conn, List<Integer> keys) throws SQLException {
        if (storedProc == null) {
            storedProc = conn.prepareCall(getCallString());
        }

        int i = 0;
        for (Integer k : keys) {
            storedProc.setInt(++i, k);
            storedProc.setInt(++i, k);
        }

        storedProc.execute();
    }
}
