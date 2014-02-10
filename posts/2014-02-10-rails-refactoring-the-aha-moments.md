---
title: "Rails Refactoring: the aha! moments"
created_at: 2014-02-10 18:21:35 +0100
kind: article
publish: true
author: Andrzej Krzywda
tags: [ 'rails', 'refactoring']
newsletter: :rails_refactoring
---



Have you ever been stuck with some code? Looking at it for minutes, hours, feeling the code smells, but not being able to fix it?

<!-- more -->


## Confident refactoring skills

I've been pair programming with many people in my career. Some of them were very skilled with refactoring. They did it very quickly, confident with their skills, confident with their tools (editors, IDEs), confident with their safety net (tests). Sometimes I watched a block of code being put in 4 different classes within 10 minutes, while being green with the tests all the time.

It wasn't just for fun. There was a deep focus involved. The aesthetics mattered. During this time we were heavily discussing how the code fits in this place. Thanks to the quick refactoring skills, we were able to experiment with many different ideas. We were not experts with this particular module, that was also a learning procedure for us.

Very often, in such situations, we had those 'aha' moments. After some code transformations, after some lessons, we were able to find the best design for the current needs.

What started as an unknown blob of code, ended as a nice structure with clear responsibilities.

Would we achieve that without the quick refactoring skills? I don't know. There are many programmers and each has its own approach to the design. It definitely worked for us, though.

How often were you involved in heated coding discussions? Was is it easy to discuss the ideas without looking at the code for each of them? What if your skills allowed you to transform the code as quickly as the ideas appear? Would that make the discussion easier?

Sometimes the 'aha' moments are very small, but they help you with a specific module. Suddenly, you know the way it should be implemented.

## Refactoring a controller

I was just working with this code. It's not mine (it's Redmine). As part of the research for my ['Rails Refactoring' book](http://rails-refactoring.com/), I was transforming this code into many possible structures.

When I started, I didn't know much about it. Before I played with it, I started some manual mutant testing to see if the tests cover most of the cases (they did).

I learnt a lot, by moving some pieces of this code into different forms. I knew this code has code smells. It does a lot of things and some better structure is possible.

I knew it's responsible for creating time entries, but not much more than that.

```
#!ruby

  def create
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
    @time_entry.safe_attributes = params[:time_entry]

    call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

    if @time_entry.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:continue]
            if params[:project_id]
              options = {
                :time_entry => {:issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                :back_url => params[:back_url]
              }
              if @time_entry.issue
                redirect_to new_project_issue_time_entry_path(@time_entry.project, @time_entry.issue, options)
              else
                redirect_to new_project_time_entry_path(@time_entry.project, options)
              end
            else
              options = {
                :time_entry => {:project_id => @time_entry.project_id, :issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                :back_url => params[:back_url]
              }
              redirect_to new_time_entry_path(options)
            end
          else
            redirect_back_or_default project_time_entries_path(@time_entry.project)
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@time_entry) }
      end
    end
  end
```

First, I applied some simple transformations to look at the problem from different perspectives. After every change the tests were run.

- Inline controller filters

- Explicitly render views with locals

- Extract Service Object with the help of SimpleDelegator

- Extract the 'if' conditional

This turned the code into this:

```
#!ruby

  def create
    CreateTimeEntryService.new(self).call()
  end

  class CreateTimeEntryService < SimpleDelegator
    def initialize(parent)
      super(parent)
    end

    def call
      project = nil
      begin
        project_id = (params[:project_id] || params[:time_entry] && params[:time_entry][:project_id])
        if project_id.present?
          project = Project.find(project_id)
        end
        issue_id = (params[:issue_id] || params[:time_entry] && params[:time_entry][:issue_id])
        if issue_id.present?
          issue = Issue.find(issue_id)
          project ||= issue.project
        end
      rescue ActiveRecord::RecordNotFound
        render_404 and return
      end
      if project.nil?
        render_404
        return
      end

      allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, project, :global => false)
      if ! allowed
        if project.archived?
          render_403 :message => :notice_not_authorized_archived_project
          return false
        else
          deny_access
          return false
        end
      end


      time_entry ||= TimeEntry.new(:project => project, :issue => issue, :user => User.current, :spent_on => User.current.today)
      time_entry.safe_attributes = params[:time_entry]

      call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => time_entry })

      if time_entry.save
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_create)
            if params[:continue]
              if params[:project_id]
                options = {
                    :time_entry => {:issue_id => time_entry.issue_id, :activity_id => time_entry.activity_id},
                    :back_url => params[:back_url]
                }
                if time_entry.issue
                  redirect_to new_project_issue_time_entry_path(time_entry.project, time_entry.issue, options)
                else
                  redirect_to new_project_time_entry_path(time_entry.project, options)
                end
              else
                options = {
                    :time_entry => {:project_id => time_entry.project_id, :issue_id => time_entry.issue_id, :activity_id => time_entry.activity_id},
                    :back_url => params[:back_url]
                }
                redirect_to new_time_entry_path(options)
              end
            else
              redirect_back_or_default project_time_entries_path(time_entry.project)
            end
          }
          format.api  { render 'show', :status => :created, :location => time_entry_url(time_entry), :locals => {:time_entry => time_entry} }
        end
      else
        respond_to do |format|
          format.html { render :new, :locals => {:time_entry => time_entry, :project => project} }
          format.api  { render_validation_errors(time_entry) }
        end
      end
    end
  end

```

As you see the 40-lines block turned into 80 lines, temporarily.

It's uglier.

I basically inlined all the dependencies. It's more explicit now. It's a look at the code from a different perspective. A perspective, without separation of concerns.

What was previously hidden in different places is now in front of me in one piece. The 'aha' moment is coming.

## The 'aha' moment

It's only now, that I realised that the controller action was in fact responsible for two different user actions:

- CreateProjectTimeEntry

- CreateIssueTimeEntry

The difference may not be huge, but this explains the number of if's in this code. What may seem to be a clever code reuse ("I'll just add this if here and there and we can now create time entries for a project as well", may also be a problem for people to understand in the future.

Where do I go with this lesson now?

After some more typical transformations, I ended with:

- extract render/redirect method

- extract exception objects from a service object

- change CRUD name to a domain one (CreateTimeEntry -> LogTime)

- return entity from service object


```
#!ruby

  def create
    if issue_id.present?
      log_time_on_issue
    else
      log_time_on_project
    end
  end

  def log_time_on_project
    log_time(nil, project_id) { do_log_time_on_project }
  end

  def log_time_on_issue
    log_time(issue_id, project_id) { do_log_time_on_issue }
  end

  def do_log_time_on_project
    time_entry = LogTime.new(self).on_project(project_id)
    respond_to do |format|
      format.html { redirect_success_for_project_time_entry(time_entry) }
      format.api { render_show_status_created }
    end
  end

  def do_log_time_on_issue
    time_entry = LogTime.new(self).on_issue(project_id, issue_id)
    respond_to do |format|
      format.html { redirect_success_for_issue_time_entry(time_entry) }
      format.api { render_show_status_created(time_entry) }
    end
  end

  def log_time(issue_id, project_id)
    begin
      yield
    rescue LogTime::DataNotFound
      render_404
    rescue LogTime::NotAuthorizedArchivedProject
      render_403 :message => :notice_not_authorized_archived_project
    rescue LogTime::AuthorizationError
      deny_access
    rescue LogTime::ValidationError => e
      respond_to do |format|
        format.html { render_new(e.time_entry, e.project) }
        format.api  { render_validation_errors(e.time_entry) }
      end
    end
  end

  class LogTime < SimpleDelegator
    class AuthorizationError           < StandardError; end
    class NotAuthorizedArchivedProject < StandardError; end
    class DataNotFound                 < StandardError; end
    class ValidationError              < StandardError
      attr_accessor :time_entry, :project
      def initialize(time_entry, project)
        @time_entry = time_entry
        @project = project
      end
    end


    def initialize(parent)
      super(parent)
    end

    def on_issue(project_id, issue_id)
      project, issue = find_project_and_issue(project_id, issue_id)
      authorize(User.current, project)
      time_entry = new_time_entry_for_issue(issue, project)
      notify_hook(time_entry)
      save(time_entry, project)
      return time_entry
    end

    def on_project(project_id)
      project = find_project(project_id)
      authorize(User.current, project)
      time_entry = new_time_entry_for_project(project)
      notify_hook(time_entry)
      save(time_entry, project)
      return time_entry
    end
  end

```



# Was it worth it?

That's an important question to ask. I wasted some time, right?

Since I'm practicing those refactoring techniques recently my skills are quite good, I didn't waste much time here. It would be much more, if I didn't have good skills, good tool support (thank you, RubyMine) and good test coverage (thanks to the Redmine team!).

What if this lesson took me 1 day of work? Sounds like a waste of time and money.

Ruby/Rails is a difficult environment to be perfect in refactoring. It requires practicing, failures, lessons, trials, patience. However, once you become more confident with your refactoring skills, you'll save a lot of time in the future. You will not only deliver more features, but also the code quality will be much better.

I think it's worth it.

---

Did you like the refactoring? I'm working on a book that explains the refactoring techniques in more detail and shows more
examples. Sign up below to receive free Refactoring lessons.


