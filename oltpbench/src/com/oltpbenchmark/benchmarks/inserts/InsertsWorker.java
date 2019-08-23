package com.oltpbenchmark.benchmarks.inserts;

import com.oltpbenchmark.api.Procedure.UserAbortException;
import com.oltpbenchmark.api.TransactionType;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.inserts.procedures.Inserts;
import com.oltpbenchmark.types.TransactionStatus;
import org.apache.log4j.Logger;

import java.sql.SQLException;

public class InsertsWorker extends Worker<InsertsBenchmark> {

    private static final Logger LOG = Logger.getLogger(InsertsWorker.class);

    private Inserts proc;

    private int nWorkers;

    private int lastKey;

    InsertsWorker(InsertsBenchmark benchmarkModule, InsertsConfig config, int id) {
        super(benchmarkModule, id);
        this.proc = this.getProcedure(Inserts.class);
        this.nWorkers = config.getTerminals();
        this.lastKey = id - nWorkers;
    }

    @Override
    protected TransactionStatus executeWork(TransactionType nextTrans) throws UserAbortException, SQLException {
        LOG.debug("Executing " + this.proc);
        
        try {
            this.lastKey += this.nWorkers;
            this.proc.run(this.conn, this.lastKey);
            this.conn.commit();

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
