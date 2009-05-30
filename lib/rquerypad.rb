=begin Rquerypad
author: Leon Li(scorpio_leon@hotmail.com)
=end
require 'md5'
class Rquerypad
    class << self
    
        def prepare_with_debug
            prepare(true)
        end
        def prepare(debug = $RQUERYPAD_DEBUG)
            return nil unless @prepared.nil?
            @prepared = true
            ActiveRecord::Base.class_eval %{
        class << self
        def group_tables(options)
          group = [options[:group], scope(:find, :group) ].join(", ")
          return [] unless group && group.is_a?(String)
          group.scan(/([\.a-zA-Z_]+).?\./).flatten
        end
        def include_eager_group?(options, tables = nil)
          ((tables || group_tables(options)) - [table_name]).any?
        end
        def references_eager_loaded_tables?(options)
          include_eager_order?(options) || include_eager_conditions?(options) || include_eager_select?(options) || include_eager_group?(options)
        end
        end
            }
            ActiveRecord::Base.class_eval %{
        require "rquerypad"
        
        class << self
          @@rquerypad_cache = {}
          alias_method(:old_find_4rqp, :find) unless method_defined?(:old_find_4rqp)
          alias_method(:old_cfswia_4rqp, :construct_finder_sql_with_included_associations) unless method_defined?(:old_cfswia_4rqp)
          VALID_FIND_OPTIONS << :inner_joins
          def find(*args)
            options = #{if [].respond_to?(:extract_options!) then "args.extract_options!" else "extract_options_from_args!(args)" end}
            if !options.empty? && (options.include?(:conditions) || options.include?(:group) || options.include?(:order))
            #  if (!options.empty? && (!options[:conditions].nil? || !options[:group].nil? || !options[:order].nil?))
	            #{"p 'original options:', options" if debug}
	            cache_key = Rquerypad.options_key(self, options)
              #p "cache_key: #\{cache_key\}"
              #p "rquerypad_cache[cache_key]: #\{rquerypad_cache[cache_key]\}"
	            if rquerypad_cache[cache_key].nil?
	              #{"p 'process for:', options" if debug}
                options = Rquerypad.new(self).improve_options!(options)
                rquerypad_cache[cache_key] = Marshal.dump(options)
                #p "rquerypad_cache[cache_key]: #\{rquerypad_cache[cache_key]\}"
              else
                options = Marshal.load(rquerypad_cache[cache_key])
	            end
              #{"p 'new options:', options" if debug}
            end
            args += [options] unless options.empty?
            old_find_4rqp *args 
          end
          def construct_finder_sql_with_included_associations(options, join_dependency)
            sql = old_cfswia_4rqp(options, join_dependency)
            #{"p('original sql', sql) unless options[:inner_joins].nil?" if debug}
            sql = Rquerypad.process_inner_join(sql, options[:inner_joins]) unless options[:inner_joins].nil?
            #{"p('new sql with inner join', sql) unless options[:inner_joins].nil?" if debug}
            sql
          end
          def rquerypad_cache
            @@rquerypad_cache
          end
        end
            }
      
            ActiveRecord::Calculations.class_eval %{
        require "rquerypad"
        module ClassMethods
          @@rquerypad_cache = {}
          alias_method(:old_construct_calculation_sql_4rqp, :construct_calculation_sql) unless method_defined?(:old_construct_calculation_sql_4rqp)
          CALCULATIONS_OPTIONS << :inner_joins
          def construct_calculation_sql(operation, column_name, options)
            if !options.empty? && (options.include?(:conditions) || options.include?(:group) || options.include?(:order))
              #{"p 'original options:', options" if debug}
              cache_key = Rquerypad.options_key(self, options)
              if rquerypad_cache[cache_key].nil?
                #{"p 'process for:', options" if debug}
                options = Rquerypad.new(self).improve_options!(options)
                rquerypad_cache[cache_key] = Marshal.dump(options)
              else
                options = Marshal.load(rquerypad_cache[cache_key])
              end
              #{"p 'new options:', options" if debug}
            end
            sql = old_construct_calculation_sql_4rqp(operation, column_name, options)
            #{"p('original sql', sql) unless options[:inner_joins].nil?" if debug}
            sql = Rquerypad.process_inner_join(sql, options[:inner_joins]) unless options[:inner_joins].nil?
            #{"p('new sql with inner join', sql) unless options[:inner_joins].nil?" if debug}
            sql
          end
          def rquerypad_cache
            @@rquerypad_cache
          end
        end
            }

        end
    
        def process_inner_join(sql, inner_joins)
            inner_joins.each {|i| sql.gsub!(/LEFT OUTER JOIN [`]?#{i}[`]?/, "INNER JOIN #{i}")} unless inner_joins.empty?
            sql
        end
    
        def options_key(obj, options)
            key = obj.to_s + options.to_a.to_s
            key = MD5.hexdigest(key) if key.length > 100
            key
        end
    end
    def initialize(obj)
        @owner = obj
        @class_name = obj.to_s.scan(/(\w*::)*([^\(]*)/)[0][1]
        # #@table_name = @class_name.pluralize.underscore
        @table_name = obj.table_name
        @tnwithdot = @table_name + "."
        @new_include = []
        @old_include = nil
        @inner_joins = []
    end
  
    def improve_options!(option_hash)
        new_options = {}
        option_hash.each do |key, value|
            if value.blank?
                new_options[key] = value
                next
            end
            key_str = key.to_s
            if key_str == "conditions"
                new_options[key] = improve_conditions(value)
            elsif (key_str == "order" || key_str == "group" || key_str == "group_field")
                new_options[key] = improve_ordergroup(value).join(", ")
            else
                new_options[key] = value
                if (key_str == "include")
                    @old_include = value
                end
            end
        end
        return new_options if @new_include.empty?
        # #generate new include
    
        
        unless @new_include.nil?
            new_options[:include] ||= []
            new_options[:include] = [new_options[:include] ] unless new_options[:include] .is_a?(Array)
            new_options[:include]  += @new_include
        end
        new_options[:include] = remove_dup_includes(new_options[:include])

        new_options[:inner_joins] = @inner_joins unless @inner_joins.empty?
        new_options
    end

    #suppose {:a => :b} {:a => {:b => :c} }, will remove {:a => :b}
    def remove_dup_includes(options)
        result = {}
        options.each {|o| result[o.inspect.gsub(/[\{\}\":]/, '') + "=>"] = o}
        result = result.sort.reverse
        keep_keys = []
        options = []
        result.each do |o|
            skip = false
            keep_keys.each {|k| skip = true if (k.index(o[0]) == 0)}
            options << o[1] unless skip
            keep_keys << o[0]
        end
        options
    end
  
    def improve_conditions(options)
        new_options = nil
        if options.is_a?(Hash)
            # #work around frozen issue
            new_options = {}
            until options.empty?
                key, value = options.shift
                new_options[process_single(key.to_s)] = value
            end
        else
            if options.is_a?(String)
                new_options = [options]
            else
                new_options = options.dup
            end
            str = new_options[0]
            return nil if str.nil?
            return options if str =~ /t[0-9]\./ #avoid t0 style generated by activerecord for associations
            qp = /['"][^."]*['"]/
            temp = str.scan(qp)
            # #replace string in quote to avoid unecessary processing
            str = str.gsub(qp, "'[??]'") unless temp.empty?
            str = str.gsub(/(([\w\(\)]+\.)+\w+)[ !><=]/) do |n|
                # #cut last char and abstract association for include
                if n =~ /^\(/
                    '(' + abstract_association(n[1..-2]) + n[-1, 1]
                else
                    abstract_association(n[0..-2]) + n[-1, 1]
                end
        
            end
            # #add @table_name on single field
            str = str.gsub(/[\.:]?[`"']?\w+[`"']?[\.]?/) {|x| (x =~ /\D+/).nil? || x[-1, 1] == "." || x[0, 1] == ":" || ["and", "or", "is", "null", "not", "like", "in"].include?(x.downcase) ? x : @tnwithdot + x}
            str = str.gsub(/\.#{@table_name}\./, ".")
            # #recover string in quote
            unless temp.empty?
                i = -1
                str = str.gsub(/\'\[\?\?\]\'/) do
                    i += 1
                    temp[i]
                end
            end
            new_options[0] = str
        end
        new_options
    end
  
    def process_single(key)
        return key.sub('=', '') if key[0, 1] == '='
        if key.include?(".")
            if /^(.+)[ ]/ =~ key
                key = key.sub("#$1", abstract_association("#$1"))
            else
                key = key.sub(/^.+$/, abstract_association(key))
            end
        else
            key = key.sub(/^.+$/, @tnwithdot + key)
        end
        key
    end
  
    def improve_ordergroup(fields)
        result = []
        if fields.is_a?(Array)
            result += fields 
        else
            result << fields
        end
        result.each_index {|i| result[i] = process_single(result[i])}
        result
    end
  
    def abstract_association(str)
        result = nil
        owner = @owner
        names = str.split(".")
        return str if names.size == 2 && names[0] == @table_name
        # #seperate assocations/tables and field
        tables, field = names[0..-2], names[-1]
        owners = []
        # #get relevant owner for each table
        tables.each_index do |i|
            # #tables[i] = tables[i].pluralize
            if i == 0
                owners[i] = owner
            else
                tname = cut_end_underscore(tables[i-1])
                r = owners[i-1].reflections[tname.to_sym].options
                owners[i] = r[:class_name].nil? ? eval(owners[i-1].to_s.gsub(/\w*$/, "")+tname.singularize.camelize) : eval("#{r[:class_name]}")
            end
        end
        owners.reverse!
        tables.reverse!
        tables.each_index do |i|
            if tables[i][-1, 1] == "_"
                tables[i].reverse!.sub!("_", "").reverse!
                @inner_joins << transfer_table_name(tables[i], owners[i])
            end
        end
        # #process special id field in a belongs_to association
        if field == "id"
            if owners[0].reflections[tables[0].to_sym].macro.to_s == "belongs_to"
                result = transfer_table_id(tables[0], owners[0])
                @inner_joins.delete(tables[0]) if @inner_joins.include?(tables[0])
                unless owners[1].nil?
                    result = transfer_table_name(tables[1], owners[1]) + "." + result
                end
                tables.delete_at(0)
                owners.delete_at(0)
                return result if tables.empty?
            end
        end
    
        # #get include
        if tables.length == 1 &&  tables[0] != @table_name
            @new_include << tables[0].to_sym unless @new_include.include?(tables[0].to_sym)
        else
            tables_clone = tables[0..-1]
            value = tables_clone.shift.to_sym
            until tables_clone.empty?
                hashes = {}
                hashes[tables_clone.shift.to_sym] = value
                value = hashes
            end
            @new_include << hashes unless hashes.nil? || @new_include.include?(hashes)
        end
        result ||= transfer_table_name(tables[0], owners[0]) + "." + field
    
    end

    def raise_error(name, owner)
        error_message = "Rquerypad error\n"
        error_message << "owner.reflections:\n"
        error_message << owner.reflections.inspect
        error_message << '\n\nnot found by key:' << name.to_sym.to_s
        raise error_message
    end
  
    def transfer_table_name(name, owner = @owner)
        raise_error(name, owner) if  owner.reflections[name.to_sym].nil?
        owner.reflections[name.to_sym].class_name.gsub(/([\w]+::)*/, "").pluralize.underscore
    end
  
    def transfer_table_id(name, owner = @owner)
        raise_error(name, owner) if  owner.reflections[name.to_sym].nil?
        owner.reflections[name.to_sym].class_name.gsub(/([\w]+::)*/, "").underscore + "_id"
    end
  
    def cut_end_underscore(str)
        str = str.reverse.sub("_", "").reverse if str[-1, 1] == "_"
        str
    end
  
    def cut_end_underscore!(str)
        str.reverse!.sub!("_", "").reverse! if str[-1, 1] == "_"
    end
end
