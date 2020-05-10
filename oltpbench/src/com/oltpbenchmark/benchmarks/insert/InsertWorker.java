package com.oltpbenchmark.benchmarks.insert;

import java.util.List;
import java.util.ArrayList;

import com.oltpbenchmark.benchmarks.insert.procedures.InsertProcedure;
import com.oltpbenchmark.api.Procedure.UserAbortException;
import com.oltpbenchmark.api.TransactionType;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.insert.procedures.Insert;
import com.oltpbenchmark.types.TransactionStatus;
import org.apache.log4j.Logger;

import java.sql.SQLException;

public class InsertWorker extends Worker<InsertBenchmark> {

    private static final Logger LOG = Logger.getLogger(InsertWorker.class);

    private int nWorkers;

    private int insertsPerTransaction;

    private int lastKey;

    InsertWorker(InsertBenchmark benchmarkModule, InsertConfig config, int id) {
        super(benchmarkModule, id);
        this.nWorkers = config.getTerminals();
        this.insertsPerTransaction = config.getInsertsPerTransaction();
        this.lastKey = (id - this.nWorkers) * this.insertsPerTransaction;
    }

    @Override
    protected TransactionStatus executeWork(TransactionType nextTrans) throws UserAbortException, SQLException {
        InsertProcedure proc = (InsertProcedure) this.getProcedure(nextTrans);

        if (LOG.isDebugEnabled()) {
            LOG.debug("Executing " + nextTrans);
        }

        try {
            this.lastKey += this.nWorkers * this.insertsPerTransaction;
            List<Integer> keys = new ArrayList<Integer>();
            for (int i = this.lastKey; i < this.lastKey + this.insertsPerTransaction; i++) {
                keys.add(i);
            }

            proc.run(this.conn, keys);

            if (LOG.isDebugEnabled()) {
                LOG.debug("Successfully completed " + nextTrans + " execution!");
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }

        return (TransactionStatus.SUCCESS);
    }
}
