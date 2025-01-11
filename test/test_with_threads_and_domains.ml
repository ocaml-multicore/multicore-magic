let test_instantaneous_domain_index () =
  if Domain.recommended_domain_count () = 1 then begin
    (* Probably running on OCaml 4.  Almost nothing to test. *)
    assert (0 = Multicore_magic.instantaneous_domain_index ())
  end
  else begin
    let test_not_same () =
      Domain.join @@ Domain.spawn
      @@ fun () ->
      let i0 = Multicore_magic.instantaneous_domain_index () in
      let i1 =
        Domain.join @@ Domain.spawn
        @@ Multicore_magic.instantaneous_domain_index
      in
      assert (i0 != i1);
      let i1' =
        Domain.join @@ Domain.spawn
        @@ Multicore_magic.instantaneous_domain_index
      in
      assert (i1 == i1')
    in
    test_not_same ();
    let module Atomic = Multicore_magic.Transparent_atomic in
    let stress () =
      let n_domains = 7 in
      let slack = 1 in
      let num_started = Atomic.make 0 |> Multicore_magic.copy_as_padded in
      let num_exited = Atomic.make 0 |> Multicore_magic.copy_as_padded in
      let failed = ref false |> Multicore_magic.copy_as_padded in

      let check () =
        let num_exited = Atomic.get num_exited in
        let i = Multicore_magic.instantaneous_domain_index () in
        let n = Atomic.get num_started - num_exited in
        if i < 0 || n + slack < i || n_domains <= i then failed := true
      in

      let domain () =
        Random.self_init ();

        Atomic.incr num_started;
        (* [Domain.DLS] is not thread-safe so it might be necessary to make sure
           we get the index before spawning threads: *)
        check ();
        let threads =
          Array.init (Random.int 5) @@ fun _ ->
          ()
          |> Thread.create @@ fun () ->
             for _ = 0 to Random.int 10 do
               Unix.sleepf (Random.float 0.01);
               check ()
             done
        in
        Array.iter Thread.join threads;
        Atomic.incr num_exited
      in

      Random.self_init ();

      let threads =
        Array.init n_domains @@ fun _ ->
        ()
        |> Thread.create @@ fun () ->
           for _ = 0 to 100 do
             Unix.sleepf (Random.float 0.01);
             Domain.join (Domain.spawn domain)
           done
      in
      Array.iter Thread.join threads;

      assert (not !failed)
    in
    stress ()
  end

let () =
  Alcotest.run "multicore-magic with threads and domains"
    [
      ( "instantaneous_domain_index",
        [ Alcotest.test_case "" `Quick test_instantaneous_domain_index ] );
    ]
