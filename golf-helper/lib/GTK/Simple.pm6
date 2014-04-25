use NativeCall;

my class GtkWidget is repr('CPointer') { };

sub gtk_widget_show(GtkWidget $widgetw)
    is native('libgtk-3.so.0')
    {*}

sub gtk_container_add(GtkWidget $container, GtkWidget $widgen)
    is native('libgtk-3.so.0')
    {*}

sub g_signal_connect_wd(GtkWidget $widget, Str $signal,
    &Handler (GtkWidget $h_widget, OpaquePointer $h_data),
    OpaquePointer $data, int32 $connect_flags)
    returns int
    is native('libgobject-2.0.so')
    is symbol('g_signal_connect_object')
    { * }

sub g_idle_add(
        &Handler(OpaquePointer $h_data),
        OpaquePointer $data)
    is native('libgtk-3.so.0')
    returns int32
    {*}

role GTK::Simple::Widget {
    has $!gtk_widget;

    method WIDGET() {
        $!gtk_widget
    }
}

role GTK::Simple::Container {
    method set_content($widget) {
        gtk_container_add(self.WIDGET, $widget.WIDGET);
        gtk_widget_show($widget.WIDGET);
    }
}

class GTK::Simple::Scheduler does Scheduler {
    my class Queue is repr('ConcBlockingQueue') { }
    my $queue := nqp::create(Queue);

    method cue(&code, :$at, :$in, :$every, :$times, :&catch ) {
        die "GTK::Simple::Scheduler does not support at" if $at;
        die "GTK::Simple::Scheduler does not support in" if $in;
        die "GTK::Simple::Scheduler does not support every" if $every;
        die "GTK::Simple::Scheduler does not support times" if $times;
        my &run := &catch 
            ?? -> { code(); CATCH { default { catch($_) } } }
            !! &code;
        nqp::push($queue, &run);
        return Nil;
    }

    method process_queue() {
        my Mu $task := nqp::queuepoll($queue);
        unless nqp::isnull($task) {
            if nqp::islist($task) {
                my Mu $code := nqp::shift($task);
                $code(|nqp::p6parcel($task, Any));
            }
            else {
                $task();
            }
        }
    }

    method loads() { nqp::elems($queue) }
}

class GTK::Simple::App does GTK::Simple::Widget
                       does GTK::Simple::Container {
    sub gtk_init(CArray[int32] $argc, CArray[CArray[Str]] $argv)
        is native('libgtk-3.so.0')
        {*}

    sub gtk_window_new(int32 $window_type)
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    sub gtk_main()
        is native('libgtk-3.so.0')
        {*}

    submethod BUILD(:$title = 'Application') {
        my $arg_arr = CArray[Str].new;
        $arg_arr[0] = $title.Str;
        my $argc = CArray[int32].new;
        $argc[0] = 1;
        my $argv = CArray[CArray[Str]].new;
        $argv[0] = $arg_arr;
        gtk_init($argc, $argv);

        $!gtk_widget = gtk_window_new(0);
    }


    method run() {
        gtk_widget_show($!gtk_widget);
        g_idle_add(
            { GTK::Simple::Scheduler.process_queue },
            OpaquePointer);
        gtk_main();
    } 
}

role GTK::Simple::Box {
    sub gtk_box_pack_start(GtkWidget, GtkWidget, int32, int32, int32)
        is native('libgtk-3.so.0')
        {*}

    multi method new(*@packees) {
        my $box = self.bless();
        $box.pack_start($_) for @packees;
        $box
    }

    method pack_start($widget) {
        gtk_box_pack_start(self.WIDGET, $widget.WIDGET, 1, 1, 0);
        gtk_widget_show($widget.WIDGET);
    }
}

class GTK::Simple::HBox does GTK::Simple::Widget does GTK::Simple::Box {
    sub gtk_hbox_new(int32, int32)
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    submethod BUILD() {
        $!gtk_widget = gtk_hbox_new(0, 0);
    }
}

class GTK::Simple::VBox does GTK::Simple::Widget does GTK::Simple::Box {
    sub gtk_vbox_new(int32, int32)
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    submethod BUILD() {
        $!gtk_widget = gtk_vbox_new(0, 0);
    }
}

class GTK::Simple::Label does GTK::Simple::Widget {
    sub gtk_label_new(Str $text)
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    sub gtk_label_get_text(GtkWidget $label)
        is native('libgtk-3.so.0')
        returns Str
        {*}

    sub gtk_label_set_text(GtkWidget $label, Str $text)
        is native('libgtk-3.so.0')
        {*}
    
    submethod BUILD(:$text = '') {
        $!gtk_widget = gtk_label_new($text);
    }

    method text() {
        Proxy.new:
            FETCH => { gtk_label_get_text($!gtk_widget) },
            STORE => -> \c, \text {
                gtk_label_set_text($!gtk_widget, text.Str);
            }
    }
}

class GTK::Simple::Entry does GTK::Simple::Widget {
    sub gtk_entry_new()
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    sub gtk_entry_get_text(GtkWidget $entry)
        is native('libgtk-3.so.0')
        returns Str
        {*}

    sub gtk_entry_set_text(GtkWidget $entry, Str $text)
        is native('libgtk-3.so.0')
        {*}
    
    submethod BUILD() {
        $!gtk_widget = gtk_entry_new();
    }

    method text() {
        Proxy.new:
            FETCH => { gtk_entry_get_text($!gtk_widget) },
            STORE => -> \c, \text {
                gtk_entry_set_text($!gtk_widget, text.Str);
            }
    }

    has $!changed_supply;
    method changed() {
        $!changed_supply //= do {
            my $s = Supply.new;
            g_signal_connect_wd($!gtk_widget, "changed",
                -> $, $ {
                    $s.more(self);
                    CATCH { default { note $_; } }
                },
                OpaquePointer, 0);
            $s
        }
    }
}

class GTK::Simple::TextView does GTK::Simple::Widget {
    sub gtk_text_view_new()
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    sub gtk_text_view_get_buffer(GtkWidget $view)
        is native('libgtk-3.so.0')
        returns OpaquePointer
        {*}

    sub gtk_text_buffer_get_text(OpaquePointer $buffer, CArray[int] $start,
            CArray[int] $end, int32 $show_hidden)
        is native('libgtk-3.so.0')
        returns Str
        {*}

    sub gtk_text_buffer_get_start_iter(OpaquePointer $buffer, CArray[int] $i)
        is native('libgtk-3.so.0')
        {*}

    sub gtk_text_buffer_get_end_iter(OpaquePointer $buffer, CArray[int] $i)
        is native('libgtk-3.so.0')
        {*}

    sub gtk_text_buffer_set_text(OpaquePointer $buffer, Str $text, int32 $len)
        is native('libgtk-3.so.0')
        {*}
    
    has $!buffer;

    submethod BUILD() {
        $!gtk_widget = gtk_text_view_new();
        $!buffer = gtk_text_view_get_buffer($!gtk_widget);
    }

   
    method text() {
        Proxy.new:
            FETCH => {
                gtk_text_buffer_get_text($!buffer, self!start_iter(),
                    self!end_iter(), 1)
            },
            STORE => -> \c, \text {
                gtk_text_buffer_set_text($!buffer, text.Str, -1);
            }
    }

    method !start_iter() {
        my $iter_mem = CArray[int].new;
        $iter_mem[31] = 0; # Just need a blob of memory.
        gtk_text_buffer_get_start_iter($!buffer, $iter_mem);
        $iter_mem
    }

    method !end_iter() {
        my $iter_mem = CArray[int].new;
        $iter_mem[16] = 0;
        gtk_text_buffer_get_end_iter($!buffer, $iter_mem);
        $iter_mem
    }

    has $!changed_supply;
    method changed() {
        $!changed_supply //= do {
            my $s = Supply.new;
            g_signal_connect_wd(
                $!buffer, "changed",
                -> $, $ {
                    $s.more(self);
                    CATCH { default { note $_; } }
                },
                OpaquePointer, 0);
            $s
        }
    }
}

class GTK::Simple::Button does GTK::Simple::Widget {
    sub gtk_button_new_with_label(Str $label)
        is native('libgtk-3.so.0')
        returns GtkWidget
        {*}

    submethod BUILD(:$label!) {
        $!gtk_widget = gtk_button_new_with_label($label);
    }

    has $!clicked_supply;
    method clicked() {
        $!clicked_supply //= do {
            my $s = Supply.new;
            g_signal_connect_wd($!gtk_widget, "clicked",
                -> $, $ {
                    $s.more(self);
                    CATCH { default { note $_; } }
                },
                OpaquePointer, 0);
            $s
        }
    }
}



