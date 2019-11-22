/******************************************************************************
 *  Copyright 2016 by OLTPBenchmark Project                                   *
 *                                                                            *
 *  Licensed under the Apache License, Version 2.0 (the "License");           *
 *  you may not use this file except in compliance with the License.          *
 *  You may obtain a copy of the License at                                   *
 *                                                                            *
 *    http://www.apache.org/licenses/LICENSE-2.0                              *
 *                                                                            *
 *  Unless required by applicable law or agreed to in writing, software       *
 *  distributed under the License is distributed on an "AS IS" BASIS,         *
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *
 *  See the License for the specific language governing permissions and       *
 *  limitations under the License.                                            *
 ******************************************************************************/

package com.oltpbenchmark.benchmarks.adversary;

import java.util.List;
import java.util.ArrayList;

import java.sql.SQLException;

import com.oltpbenchmark.api.Procedure.UserAbortException;
import com.oltpbenchmark.api.TransactionType;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.adversary.procedures.BaseQuery;
import com.oltpbenchmark.types.TransactionStatus;

import org.apache.log4j.Logger;

public class AdversaryWorker extends Worker<AdversaryBenchmark> {

    private static final Logger LOG = Logger.getLogger(AdversaryLoader.class);

    private final AdversaryConfig config;

    private int nWorkers;

    private int lastKey;

    private int hotKey;

    public AdversaryWorker(AdversaryBenchmark benchmarkModule, AdversaryConfig config, int id) {
        super(benchmarkModule, id);
        this.config = config;
        this.nWorkers = config.getTerminals();
        this.lastKey = id;
        this.hotKey = config.getHotKey();
    }

    @Override
    protected TransactionStatus executeWork(TransactionType nextTrans) throws UserAbortException, SQLException {
        BaseQuery procAdversary = (BaseQuery)this.getProcedure(nextTrans);

        if (LOG.isDebugEnabled()) {
            LOG.debug("Executing " + procAdversary);
        }
        
        try {
            List<Integer> keys = new ArrayList<Integer>();
            int start = this.lastKey * config.getInserts();
            for (int i = start; i < start + config.getInserts(); i++) {
                keys.add(i);
            }

            procAdversary.run(this.conn, this.hotKey, keys);
            this.conn.commit();

            this.lastKey += this.nWorkers;
            if (LOG.isDebugEnabled()) {
                LOG.debug("Successfully completed " + procAdversary + " execution!");
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }

        return (TransactionStatus.SUCCESS);
    }
}
