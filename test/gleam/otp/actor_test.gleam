import gleam/otp/actor.{Continue}
import gleam/erlang/process.{Pid}
import gleam/otp/process as legacy
import gleam/otp/system
import gleam/dynamic.{Dynamic}
import gleeunit/should
import gleam/result
import gleam/io

pub fn get_state_test() {
  assert Ok(subject) =
    actor.start("Test state", fn(_msg, state) { Continue(state) })

  subject
  |> process.subject_owner
  |> system.get_state
  |> should.equal(dynamic.from("Test state"))
}

external fn get_status(Pid) -> Dynamic =
  "sys" "get_status"

pub fn get_status_test() {
  assert Ok(subject) = actor.start(Nil, fn(_msg, state) { Continue(state) })

  subject
  |> process.subject_owner
  |> get_status
  // TODO: assert something about the response
}

pub fn failed_init_test() {
  actor.Spec(
    init: fn() { actor.Failed(dynamic.from(legacy.Normal)) },
    loop: fn(_msg, state) { Continue(state) },
    init_timeout: 10,
  )
  |> actor.start_spec
  |> result.is_error
  |> should.be_true
}

pub fn suspend_resume_test() {
  assert Ok(subject) = actor.start(0, fn(_msg, iter) { Continue(iter + 1) })

  // Suspend process
  subject
  |> process.subject_owner
  |> system.suspend
  |> should.equal(Nil)

  // This normal message will not be handled yet so the state remains 0
  actor.send(subject, "hi")

  // System messages are still handled
  subject
  |> process.subject_owner
  |> system.get_state
  |> should.equal(dynamic.from(0))

  // Resume process
  subject
  |> process.subject_owner
  |> system.resume
  |> should.equal(Nil)

  // The queued regular message has been handled so the state has incremented
  subject
  |> process.subject_owner
  |> system.get_state
  |> should.equal(dynamic.from(1))
}

pub fn subject_test() {
  assert Ok(subject) = actor.start("state 1", fn(msg, _state) { Continue(msg) })

  subject
  |> process.subject_owner
  |> io.debug
  |> system.get_state()
  |> should.equal(dynamic.from("state 1"))

  actor.send(subject, "state 2")

  subject
  |> process.subject_owner
  |> system.get_state()
  |> should.equal(dynamic.from("state 2"))
}
