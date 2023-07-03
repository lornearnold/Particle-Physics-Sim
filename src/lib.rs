#![allow(warnings)]
pub mod windowInit;
pub mod client;
pub mod wgpu_config;
pub mod wgpu_structs;
pub mod wgpu_prog;
use std::ptr::null;
use winit::dpi::PhysicalSize;
use log::*;
 #[cfg(target_arch="wasm32")] 
use wasm_bindgen::prelude::*;
#[cfg(target_arch="wasm32")] 
use console_log::*;

#[cfg(target_arch="wasm32")] 
#[wasm_bindgen]
pub fn webmain(){

    std::panic::set_hook(Box::new(console_error_panic_hook::hook));
    console_log::init_with_level(log::Level::Warn).expect("Couldn't initialize logger");
    let client = async_std::task::block_on(client::Client::new());
    
}