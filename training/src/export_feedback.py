"""Export confirmed feedback for an explicit offline retraining job."""
import argparse, csv, os
from pathlib import Path
FIELDS=['title','category','secondary_category','source','timestamp']

def write_feedback(rows, output: Path):
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open('w',newline='',encoding='utf-8') as f:
        writer=csv.writer(f);writer.writerow(FIELDS);writer.writerows(rows)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--database-url',default=os.getenv('DATABASE_URL'))
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    if not args.database_url: p.error('set DATABASE_URL or pass --database-url')
    import psycopg
    with psycopg.connect(args.database_url) as conn:
        with conn.cursor() as cursor:
            cursor.execute('SELECT f.title,f.category,f.secondary_category,f.source,f.created_at FROM classifier_feedback f JOIN records r ON r.id=f.record_id WHERE r.is_committed ORDER BY f.created_at,f.record_id')
            write_feedback(cursor,args.output)
    print(f'Feedback exported to {args.output}')

if __name__=='__main__':main()
