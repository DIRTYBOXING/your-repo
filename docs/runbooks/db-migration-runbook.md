# DB Migration Runbook — Snapshot and Restore

## Purpose

Snapshot the DB before running migrations and provide exact restore steps if migration fails.

---

## Pre-migration snapshot (Cloud SQL managed Postgres)

1. Create an on-demand backup
   ```bash
   gcloud sql backups create --instance=<CLOUD_SQL_INSTANCE> --project=<GCP_PROJECT>
   ```
2. Note the backup ID and timestamp. Confirm backup completed in Cloud Console.

3. Optional: export a logical dump
   ```bash
   gcloud sql export sql <CLOUD_SQL_INSTANCE> gs://<BUCKET>/dfc_backup_$(date +%Y%m%d_%H%M).sql.gz \
     --database=<DB_NAME> --project=<GCP_PROJECT>
   ```

---

## Pre-migration snapshot (self-hosted Postgres)

1. Logical dump (fast, portable)
   ```bash
   PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -F c -b -v -f "backups/dfc_pre_migration_$(date +%Y%m%d_%H%M).dump"
   ```
2. Verify dump integrity

   ```bash
   pg_restore -l "backups/dfc_pre_migration_YYYYMMDD_HHMM.dump" | head
   ```

3. Optional filesystem snapshot if using managed disks or EBS.

---

## Restore procedure (Cloud SQL point-in-time or backup restore)

- **Point-in-time restore** (if enabled)
  ```bash
  gcloud sql backups restore <BACKUP_ID> --instance=<CLOUD_SQL_INSTANCE> --project=<GCP_PROJECT>
  ```
- **Restore from export SQL**
  ```bash
  gcloud sql import sql <CLOUD_SQL_INSTANCE> gs://<BUCKET>/dfc_backup_YYYYMMDD_HHMM.sql.gz --database=<DB_NAME> --project=<GCP_PROJECT>
  ```

## Restore procedure (self-hosted Postgres)

1. Stop writes to the DB (put service in maintenance mode).
2. Restore from dump
   ```bash
   PGPASSWORD=$DB_PASSWORD pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -v "backups/dfc_pre_migration_YYYYMMDD_HHMM.dump"
   ```
3. Verify schema and data integrity. Run smoke tests.

---

## Emergency rollback if migration caused schema break

1. Immediately set service to read-only or redirect traffic to a maintenance page.
2. Restore DB from pre-migration backup (Cloud SQL or pg_restore).
3. Redeploy previous service image:
   ```bash
   gcloud run deploy <CLOUD_RUN_SERVICE> --image gcr.io/<GCP_PROJECT>/dfc-audit:<previous-tag> --region <GCP_REGION> --project <GCP_PROJECT> --no-allow-unauthenticated
   ```
4. Validate application health and data integrity. Notify stakeholders and open incident ticket.

---

## Testing the runbook

- Test restore quarterly in a staging environment.
- Document RTO and RPO for each environment and update the runbook after each test.
