use fdr;
drop procedure if exists insert000;

delimiter |

  CREATE PROCEDURE insert000(in_hot_k INT, in_hot_v INT)
  BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
                           BEGIN
                             ROLLBACK;
                           END;

    START TRANSACTION;

    UPDATE HOTKEY
       SET V = in_hot_v
     WHERE K = in_hot_k;

	  COMMIT;

  END|

    delimiter ;
