package com.oltpbenchmark.benchmarks.insert;

import com.oltpbenchmark.api.Procedure.UserAbortException;
import com.oltpbenchmark.api.TransactionType;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.insert.procedures.Insert;
import com.oltpbenchmark.types.TransactionStatus;
import org.apache.log4j.Logger;

import java.sql.SQLException;

public class InsertWorker extends Worker<InsertBenchmark> {

    private static final Logger LOG = Logger.getLogger(InsertWorker.class);

    private Insert proc;

    private int nWorkers;

    private int lastKey;

    InsertWorker(InsertBenchmark benchmarkModule, InsertConfig config, int id) {
        super(benchmarkModule, id);
        this.proc = this.getProcedure(Insert.class);
        this.nWorkers = config.getTerminals();
        this.lastKey = id - nWorkers;
    }

    @Override
    protected TransactionStatus executeWork(TransactionType nextTrans) throws UserAbortException, SQLException {
        LOG.debug("Executing " + this.proc);

        try {
            this.lastKey += this.nWorkers;
            this.proc.run(this.conn, this.lastKey);

            if (LOG.isDebugEnabled()) {
                LOG.debug("Successfully completed " + this.proc + " execution!");
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }

        return (TransactionStatus.SUCCESS);
    }
}
