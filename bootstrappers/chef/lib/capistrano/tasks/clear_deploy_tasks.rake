deploy_tasks = %w(
  deploy
  deploy:check
  deploy:check:directories
  deploy:check:linked_dirs
  deploy:check:linked_files
  deploy:check:make_linked_dirs
  deploy:cleanup
  deploy:cleanup_rollback
  deploy:finished
  deploy:finishing
  deploy:finishing_rollback
  deploy:log_revision
  deploy:published
  deploy:publishing
  deploy:revert_release
  deploy:reverted
  deploy:reverting
  deploy:rollback
  deploy:set_current_revision
  deploy:started
  deploy:starting
  deploy:symlink:linked_dirs
  deploy:symlink:linked_files
  deploy:symlink:release
  deploy:symlink:shared
  deploy:updated
  deploy:updating
  install
)

deploy_tasks.each do |task|
  Rake::Task[task].clear
end
