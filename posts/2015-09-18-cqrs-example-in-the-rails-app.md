---
title: "CQRS example in the Rails app"
created_at: 2015-09-18 14:08:20 +0200
kind: article
publish: true
author: Tomasz Rybczyński
tags: [ 'cqrs', 'ddd', 'read_model' ]
newsletter: arkency_form
img: "cqrs-example/photo.jpeg"
---

<p>
  <figure>
    <img src="<%= src_fit("cqrs-example/photo.jpeg") %>" width="100%" />
  </figure>
</p>

Recently I have worked in a new project for some time. We implement an application where one functionality is to show an organization’s (tree-like) structure.
The structure contains information about relations between employees. I have been thinking how to build this feature.
I was wondering if I should go typical way implementing all CRUD actions. In this case I would have to generate the structure for each call.
I thought It will be faster. It is a startup. So until the project is young performance is not a problem.
Although after few syncs we decided to go an another way.

<!-- more -->

I am fascinated by the DDD and CQRS approaches. In Arkency we are used to saying that every time we return to the "Implementing DDD" book we realize that it has answers to all the questions and doubts.
So going back to the feature we decided to implement the structure as a Read Model.


## Example

I love examples so I will not leave you hanging. Our app is split into two parts. We have a frontend implemented in React and a Rails backend.
I will focus only on the backend part. If you are interested in how we deal with React you can read some of ours [books](http://blog.arkency.com/products/).
In next steps I will show you how we implemented simple CQRS. I will focus on building a Read Model using events.

Starting from the top. The following example shows the controller with basic actions. As you can see we simply call **Application services** where each one has a separate responsibility.
In clean CQRS we should use **Commands**. We will refactor it in a next step.

```ruby

class TeamsController < ApplicationController
  before_action :authenticate_user_from_token!

  def in_organization
    teams = AppServices::TeamsInOrganization.new.(params[:organization_id])
    render json: { teams: teams }
  end

  def show
    AppServices::GetTeam.new.(params[:id])
  end

  def create
    AppServices::AddNewTeam.new.(params[:team])
  end

  def update
    AppServices::EditTeamData.new.(params[:team])
  end

  def destroy
    AppServices::RemoveTeam.new.(params[:id])
  end
end
```

The following example shows one app service. We use this service to create new a Team.

```ruby

module AppServices
  class AddNewTeam
    include EventStore::Injector

    def initialize(team_repository = ::OrganizationBc::Adapters::TeamRepository.new)
      @team_repository = team_repository
    end

    def call(team_data)
      team = create_new_team(team_data)
      publish_team_created(team_data, team.id, parent.department)
      team
    end

    private
    attr_reader :team_repository

    def create_new_team(team_data)
      add_new_team = OrganizationBc::Teams::Services::AddNewTeam.new(team_repository)
      add_new_team.(team_data)
    end

    def publish_team_created(team, team_id, department)
      stream_name = "team/#{team_id}"
      event = ::Event::TeamCreated.new({
                                           data: {
                                               team: {
                                                   id:              team_id,
                                                   organization_id: team[:organization_id],
                                                   name:            team[:name],
                                                   parent_id:       team[:parent_id],
                                                   department:      team[:department],
                                                   type:            'team'
                                               }
                                           }
                                       })
      event_store.publish_event(event, stream_name)
    end
  end
end
```

```ruby

module OrganizationBc
  module Teams
    module Services
      class AddNewTeam
        def initialize(repository)
          @repository = repository
        end

        def call(team)
          team = Team.new({
            id:              team[:id],
            name:            team[:name],
            organization_id: team[:organization_id]
          })
          repository.create(team)
        end

        private
        attr_reader :repository
      end
    end
  end
end
```

I have chosen a simple service to focus on most important parts. As you can see we call a **domain service** to create Team model and save it into the Database.
Team is an aggregate root in relation Team <-> Members. After creating a Team we publish event to the Event Store. We use our own Event Store called **RailsEventStore**.
You can check out the [github repository](https://github.com/arkency/rails_event_store). Publishing event should be placed in aggregate but It was a first step to put in an app service.
We don't use the Event Sourcing. We decided to save a „current” state for now. Event Sourcing is a completely orthogonal concept to CQRS. Doing CQRS does not require event sourcing.
But we save all events so It will be very ease to build an aggregate's state using events.

We inject the EventStore instance using a custom injector. The whole setup you can see bellow.

```ruby

module EventStore
  module Injector

    def event_store
      @event_store ||= Rails.application.config.event_store
    end

  end
end
```

```ruby

Rails.application.configure do
  #other stuff
  config.event_store = EventStore::SetupEventStore.new.()
end
```

```ruby

module EventStore
  class SetupEventStore

    def call
      event_store                     = RailsEventStore::Client.new
      structure_read_model            = OrganizationBc::ReadModels::Structure.new
      event_store = config_structure_handler(structure_read_model, event_store)
      event_store
    end

    private

    def config_structure_handler(structure_read_model, event_store)
      events = ['Event::OrganizationCreated',
                'Event::MemberAdded',
                'Event::MemberUpdated',
                'Event::MemberDeleted',
                'Event::MemberUnassigned',
                'Event::TeamCreated',
                'Event::TeamUpdated',
                'Event::TeamRemoved']
      event_store.subscribe(structure_read_model, events)
      event_store
    end
  end
end
```

So the **Write** part is almost done. In the `SetupEventStore` class we define event handler called `OrganizationBc::ReadModels::Structure` for our Read Model.
We subscribe it to handle set of events.

```ruby

module OrganizationBc
  module ReadModels
    class Structure
      def initialize(repository = ::OrganizationBc::Adapters::StructureReadModelRepository.new)
        @repository = repository
      end

      def handle_event(event)
        case event.event_type
          when 'Event::OrganizationCreated'
            create_structure_for_organization(event.data[:organization])
          when 'Event::MemberAdded'
            update_structure(event.data[:member]) { |structure, member| add_member_to_model(structure, member) }
          when 'Event::MemberUpdated'
            update_structure(event.data[:member]) { |structure, member| update_member_in_model(structure, member) }
          when 'Event::MemberDeleted'
            update_structure(event.data[:member]) { |structure, member| remove_member_from_model(structure, member) }
          when 'Event::MemberUnassigned'
            update_structure(event.data[:member]) { |structure, member| remove_member_from_model(structure, member) }
          when 'Event::TeamCreated'
            update_structure(event.data[:team]) { |structure, team| add_team_to_model(structure, team) }
          when 'Event::TeamUpdated'
            handle_team_updated(event)
          when 'Event::TeamRemoved'
            update_structure(event.data[:team]) { |structure, team| remove_team_from_model(structure, team) }
        end
      end

      private
      attr_reader :repository

      def create_structure_for_organization(organization)
        save_structure(organization[:id])
      end

      def update_structure(element)
        org_structure = get_organization_structure(element[:organization_id])
        yield(org_structure[:structure], element.merge!(children: []))
        save_structure(element[:organization_id], org_structure)
      end

      def add_member_to_model(people, member)
        if member[:parent_id] == ''
          people.push member
        else
          people.each do |person|
            if person['id'] == member[:parent_id]
              person['children'] << member
            else
              add_member_to_model(person['children'], member)
            end
          end
        end
      end

      def update_member_in_model(people, member)
        people.each_with_index do |person, index|
          if person['id'] == member[:id]
            people[index] = member
          else
            update_member_in_model(person['children'], member)
          end
        end
      end

      def remove_member_from_model(people, member)
        people.each_with_index do |person, index|
          if person['id'] == member[:id]
            people.delete_at(index)
          else
            remove_member_from_model(person['children'], member)
          end
        end
      end

      def add_team_to_model(people, team)
        people.each do |person|
          if person['id'] == team[:parent_id]
            person['children'] << team
          else
            add_team_to_model(person['children'], team)
          end
        end
      end

      def handle_team_updated(event)
        #code
      end

      def update_team_in_nodes(nodes, team)
        nodes.map do |node|
          if node['id'] == team[:id]
            team[:children] = node['children']
            team
          else
            node['children'] = update_team_in_nodes(node['children'], team)
            node
          end
        end
      end

      def remove_team_from_model(people, team)
        people.each_with_index do |person, index|
          if person['id'] == team[:id]
            people.delete_at(index)
          else
            remove_team_from_model(person['children'], team)
          end
        end
      end

      def get_organization_structure(organization_id)
        record = repository.find_by_organization_id!(organization_id)
        {structure: record.model['structure'], departments: record.model['departments'], version: record.version}
      end

      def save_structure(organization_id, model = {structure: [], departments: [], version: 0})
        repository.create(organization_id, model)
      end
    end
  end
end
```

The organization's structure is a tree structure. Each **Team** has relation to a parent member and collection of child notes.
These nodes are team’s members. We modify the structure's model and save in Postgres Database for each handled event. We save model in JSON representation.
We save a new record in each update to keep whole change history. The following example shows how the repository looks like.

```ruby

module OrganizationBc
  module Adapters
    class StructureReadModelRepository
      class StructureReadModel < ActiveRecord::Base
        self.table_name = 'structures_read_models'
      end

      ReadModelNotFound = Class.new(StandardError)

      def create(organization_id, model)
        version = model[:version] + 1
        model[:version] = version
        record = StructureReadModel.new({ organization_id: organization_id, version: version, model: model})
        record.save!
      end


      def find_by_organization_id!(organization_id)
        record = find_by_organization_id(organization_id)
        raise ReadModelNotFound.new if record.nil?
        record
      end

      private

      def find_by_organization_id(organization_id)
        StructureReadModel.where(organization_id: organization_id).order(:version).last
      end

    end
  end
end
```

When we have build Read Model the last step is to create query for fetching model. We have separate module called `AppQueries` where we keep all queries.
So the **Read** part is only one class. That's all.

```ruby

module AppQueries
  class LoadOrganizationStructure

    def initialize(repository = OrganizationBc::Adapters::StructureReadModelRepository.new)
      @repository = repository
    end

    def call(organization_id)
      repository.find_by_organization_id!(organization_id)
    end

    private
    attr_reader :repository
  end
end
```

## Conclusion

I can only say that was great decision to start this way. Now I now that we save a lot of time on investigation performance problems in the future. Off course
the most important thing is to choose if CQRS is a good starting point. If you have simple CRUD feature it will be unnecessary.

I didn't focus on test part. I think It is a great subject for a separate post. If you are interested in testing event sourced app you can check this [post](http://blog.arkency.com/2015/07/testing-event-sourced-application/).

All code used in this post you can find [here](https://gist.github.com/rybex/3d150e2e850fb5b8ea46).


