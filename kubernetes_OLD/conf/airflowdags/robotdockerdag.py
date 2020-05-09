'''
sudo apt install -y docker-ce

sudo apt install -y docker-compose

sudo apt install -y python-pip

pip install apache-airflow
pip install docker


remove docker

To identify what installed package you have:

dpkg -l | grep -i docker

#Remove

sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-compose golang-docker-credential-helpers docker-ce-cli python-dockerpty
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-compose golang-docker-credential-helpers docker-ce-cli python-dockerpty


'''
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta
from airflow.operators.docker_operator import DockerOperator

# Our notification function which simply prints out some fo the information passed in to the SLA notification miss.
def print_sla_miss(dag, task_list, blocking_task_list, slas, blocking_tis):
    print ('SLA was missed on DAG %(dag)s by task id %(blocking_tis)s with task list %(task_list)s which are blocking %(blocking_task_list)s') % locals()



default_args = {
        'owner'                 : 'airflow',
        'description'           : 'Use of the DockerOperator',
        'depend_on_past'        : False,
        'start_date'            : datetime(2018, 1, 3),
        #'start_date': datetime(2019, 6, 27),
        #'start_date': datetime.now(),	 
		'email': None,
        'email_on_failure'      : False,
        'email_on_retry'        : False,
        'retries'               : 0,
        #'retry_delay'           : timedelta(minutes=5)
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
    # 'wait_for_downstream': False,
    # 'dag': dag,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function,
    # 'on_success_callback': some_other_function,
    # 'on_retry_callback': another_function,
    # 'sla_miss_callback': yet_another_function,
# 'trigger_rule': 'all_success'		
}


'''
with DAG('robot_docker_dag', default_args=default_args, schedule_interval="0 1 * * *", catchup=False) as dag:
        t1 = BashOperator(
                task_id='print_current_date',
                bash_command='date'
        )

        t2 = DockerOperator(
                task_id='docker_command',
                #image='centos:latest',
                image='pythonrobot',                
                api_version='auto',
                auto_remove=True,
				xcom_push=True,
                #command="echo 'starting docker' && /bin/sleep 30",
                docker_url="unix://var/run/docker.sock",
                network_mode="bridge"
        )

        t3 = BashOperator(
                task_id='print_hello',
                bash_command='echo "hello world"'
        )

        t1 >> t2 >> t3
'''

# o pólnocy
dag = DAG('robot_docker_dag', 
           default_args=default_args, 
		   schedule_interval="0 3 * * *", 
		   #schedule_interval=timedelta(hours=1),
 		   # Add our method as a SLA callback
		   sla_miss_callback=print_sla_miss,
		   catchup=False)

'''
t1 = BashOperator(
                task_id='print_current_date',
                bash_command='date',
				dag=dag,
        )
'''
dockertask = DockerOperator(
                task_id='execute_docker_container',
                #image='centos:latest',
                image='pythonrobot',                
                api_version='auto',
                auto_remove=True,
				environment={
                        'XXXX': "python3",
                        'XXX2': "/spark",
                        'TZ': "Europe/Warsaw"
                },
				#volumes=['/home/ubuntu/pythonrobotenvironment/robot_chd2rm/config/config.txt:/app/chd2rm/config.txt'],								
				xcom_push=True,
				#xcom_all=True,
                #command="echo 'starting docker' && /bin/sleep 30",
                docker_url="unix://var/run/docker.sock",
                network_mode="bridge",
				sla=timedelta(seconds=1),
				dag=dag,
        )
'''
t3 = BashOperator(
                task_id='print_hello',
                bash_command='echo "hello world"',
				dag=dag,
        )
'''		
#t1 >> dockertask >> t3
		
dockertask.doc_md = """\
#### Task Documentation
You can document your task using the attributes `doc_md` (markdown),
`doc` (plain text), `doc_rst`, `doc_json`, `doc_yaml` which gets
rendered in the UI's Task Instance Details page.
![img](http://montcs.bloomu.edu/~bobmon/Semesters/2012-01/491/import%20soul.png)
"""

dag.doc_md = __doc__



'''
finisher = BashOperator(
    task_id="finish_task",
    bash_command='echo "{{ ti.xcom_pull(key="k1") }}" "{{ ti.xcom_pull(key="k2") }}" "{{ ti.xcom_pull(task_ids="execute_docker_container") }}"',
    dag=dag,
)
'''

#dockertask >> finisher