# This is for dbglobalvehicle chain
class hostroles::app::dbcat ( $lv_size = '199G', $tmpdir = '/db/tmp' ) {
  include yum::
  notify { 'hostrole':
    message  => 'This system is using hostroles::db::mysql::inv::dbcat',
    withpath => false,
  }
  case $::hostname {
    'server': {
      ## Master
      $master = ''
      $repo = 'http://yumrepo2.vt.dealer.ddc/repos/mysql/mysql4.1/6/x86_64/MySQL-server-standard-4.1.22-0.rhel4.x86_64.rpm'
      $mysqlversion = '4.1.22-0.rhel4'
      $mysqllibsversion = '5.1.47-1.rhel5'
      $mysql_server_package = 'MySQL-server-standard'
    }
    '': {
      $master = ''
      $repo = 'http://se-install-files.vt.dealer.ddc/websol/mysql/5.0/MySQL-server-community-5.0.96-1.rhel5.x86_64.rpm'
      $mysqlversion = '5.0.96-1.rhel5'
      $mysqllibsversion = '5.0.96-1.rhel5'
      $mysql_server_package = 'MySQL-server-community'
    }
    '': {
      $master = ''
      $repo = 'http://yumrepo2.vt.dealer.ddc/repos/mysql/mysql5.1/6/x86_64/MySQL-server-community-5.1.68-1.rhel5.x86_64.rpm'
      $mysqlversion = '5.1.68-1.rhel5'
      $mysqllibsversion = '5.1.68-1.rhel5'
      $mysql_server_package = 'MySQL-server-community'
    }
    'l': {
      $master = ''
      $repo = 'http://repo.mysql.com/yum/mysql-5.5-community/el/7/x86_64/mysql-community-client-5.5.62-2.el7.i686.rpm'
      $mysqlversion = '5.5.62-2.el7'
      $mysqllibsversion = '5.5.62-2.el7'
      $mysql_server_package = 'mysql-community-client'
    }
    '','': {
      package { 'mariadb-libs-1:5.5.60-1.el7_5.x86_64':
        ensure => 'absent',
      }
      $master = ''
      $repo = 'http://repo.mysql.com/yum/mysql-5.5-community/el/7/x86_64/mysql-community-client-5.5.62-2.el7.i686.rpm'
      $mysqlversion = '5.5.62-2.el7'
      $mysqllibsversion = '5.5.62-2.el7'
      $mysql_server_package = 'MySQL-community-client'
    }
    default: { }
  }

  $octets = split($::ipaddress, '[.]')
  $server_id = sprintf('%03d%03d%03d', $octets[1], $octets[2], $octets[3])

  # Make sure our variables are set before we try to use them as parameters for lower level classes
  #Class['hostroles::app::dbcat'] -> Class['platforms::mysql'] -> Class['::mysql::server']
  # Make sure we've created /db before we try to make /db/tmp ...
  #Class['hostroles::app::dbcat'] -> Class['platforms::mounts::mysql_tmpfs']

  $mysqld_override_initial = {
    'bind-address'                    => '0.0.0.0',
    'skip_slave_start'                => true,
    'datadir'                         => '/db/mysql', # The REAL datadir value, overiding the fake one used for LVM above...
    'slave-load-tmpdir'               => '/db/slave_tmp',
    'log_slow_queries'                => "/db/logs/${::hostname}-slow.log",
    'ssl-disable'                     => true,
    'relay-log'                       => "/db/logs/relay/${::hostname}-bin.extension",
    'log-bin'                         => "/db/logs/bin/${::hostname}-bin.extension",
    'innodb_flush_log_at_trx_commit'  => '1',
    'sync_binlog'                     => '1',
    'expire_logs_days'                => '1',
    'report-host'                     => $::fqdn,
    'server-id'                       => $server_id,
    'slave-skip-errors'               => '1062,1050,1061',
    'skip_slave_start'                => true,
    'low_priority_updates'            => true,
    'key_buffer_size'                 => '1G',
    'binlog_cache_size'               => '1M #no need to inc - JM http://dev.mysql.com/doc/refman/4.1/en/server-system-variables.html#sysvar_binlog_cache_size',
    'max_binlog_size'                 => '52428800',
    'sort_buffer_size'                => '128M #http://dev.mysql.com/doc/refman/4.1/en/server-system-variables.html#option_mysqld_sort_buffer_size',
    'join_buffer_size'                => '128M #http://dev.mysql.com/doc/refman/4.1/en/server-system-variables.html#option_mysqld_join_buffer_size',
    'net_buffer_length'               => '80K',
    'wait_timeout'                    => '28800',
    'read_only'                       => true,
    'delay_key_write'                 => 'ALL',
    'max_connections'                 => '8192',
    'back_log'                        => '50',
    'max_connect_errors'              => '10',
    'read_buffer_size'                => '10M',
    'read_rnd_buffer_size'            => '80M',
    'bulk_insert_buffer_size'         => '64M',
    'innodb_log_files_in_group'       => '2',
    'innodb_flush_log_at_trx_commit'  => '1',
    'innodb_file_per_table'           => '1',
    'innodb_buffer_pool_size'         => '1G',
    'innodb_additional_mem_pool_size' => '64M',
    'innodb_lock_wait_timeout'        => '120',
    'query_cache_size'                => '64M #http://www.mysqlperformanceblog.com/2006/09/29/what-to-tune-in-mysql-server-after-installation/',
    'query_cache_limit'               => '2M',
    'query_cache_type'                => '1',
    'long_query_time'                 => '15',
    'log_queries_not_using_indexes'   => true,
    'skip-name-resolve'               => true,
  }
  $mysqld_override_final = $::hostname ? {
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    '' => merge($mysqld_override_initial, {
        'replicate-do-db'    => 'global_vehicle', #for account/password updates
        'expire_logs_days'   => '1' # nexus binlogs can be over 50GB/day
      } ),
    default                => $mysqld_override_initial,
  }
  class { 'platforms::mounts::mysql_tmpfs': tmpdir => $tmpdir, }
  class { 'platforms::mysql':
    ddc_server_rpm_url    => $repo,
    mysql_manage_root_pw  => false, # Why does this not just default to false in the platform? :|
    mysql_server_package  => 'MySQL-server-standard',
    mysql_server_version  => $mysqlversion,
    mysql_libs_package    => 'MySQL-shared-compat',
    mysql_libs_version    => $mysqllibsversion, # This is the version that matches mysqld 4.1.22
    mysql_repl_type       => 'slave',
    mysql_cur_master      => $master,
    mysql_datadir         => '/db', # actually override to /db/mysql below, but this is what we use to setup LVM...
    mysql_tmpdir          => $tmpdir,
    mysql_errorlog        => "/db/logs/${::hostname}.err",
    manage_lvm            => true,
    with_xinetd           => true,
    data_pv_names         => ['/dev/sdb'], # Expects an array, errors out if simple string
    data_vg_name          => 'mysql',
    data_lv_name          => 'data',
    data_lv_size          => $lv_size, # Does not accept "T" as a valid size indicator...
    data_lv_fs_type       => 'ext4',
    data_lv_mount_opt     => 'defaults,noatime',
    # All the below ends up in my.cnf
    mysql_manage_config   => true,
    mysql_override        => {
      'no-auto-rehash' => true,
    },
    mysqld_override       => $mysqld_override_final,
    mysqld_safe_override  => {
      'open-files-limit' => '8192',
    },
    mysqlhotcopy_override => {
      'interactive-timeout' => true,
    },
  }
  class { 'platforms::se::base':
    sudo => 'includedir_adminonly',
  }
  class { 'platforms::sysctl::db': }

  file_line { 'slow_query_killer':
    ensure => present,
    path   => '/etc/rc.local',
    line   => '/db/scripts/dbmon.pl --killlong=120 --daemon',
    match  => 'dbmon\.pl',
  }
  include platforms::sysctl::db
  include platforms::mysql::utilities

  # Set limits appropriately for this sort of use
  platforms::limitsd{'mysql':
    user     => 'mysql',
    limits   => 8192,
    priority => 91,
  }
}
