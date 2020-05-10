/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
  *
 * Copyright (C) 2003 Mark Wong & Open Source Development Lab, Inc.
 * Copyright (C) 2004 Alexey Stroganov & MySQL AB.
  *
 * Based on TPC-C Standard Specification Revision 5.0 Clause 2.5.2.
 * July 10, 2002
 *     Not selecting n/2 for customer search by c_last.
 * July 12, 2002
 *     Not using c_d_id and c_w_id when searching for customers by last name
 *     since there are cases with 1 warehouse where no customers are found.
 * August 13, 2002
 *     Not appending c_data to c_data when credit is bad.
 */

use fdr;
drop procedure if exists insertsp004;

delimiter |

  CREATE PROCEDURE insertsp004(in_k1 INT, in_v1 INT,
                               in_k2 INT, in_v2 INT,
                               in_k3 INT, in_v3 INT,
                               in_k4 INT, in_v4 INT)
  BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
                           BEGIN
                             ROLLBACK;
                           END;

    START TRANSACTION;

    INSERT INTO KV (K, V)
    VALUES (in_k1, in_v1),
           (in_k2, in_v2),
           (in_k3, in_v3),
           (in_k4, in_v4);

	  COMMIT;

  END|

    delimiter ;





