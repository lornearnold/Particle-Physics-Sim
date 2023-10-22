@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(4) @binding(0) var<storage, read_write> bonds: array<i32>;
@group(5) @binding(0) var<storage, read_write> bond_info: array<vec2<i32>>;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625;
    let gravity = 9.8 * deltaTime;
    let stiffness: f32 = 1000.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.5; // Damping factor, can be adjusted

    velocities_buf[id] = vec2(velocities_buf[id].x, velocities_buf[id].y - gravity);

    for(var i = 0u; i<arrayLength(&radii); i++){
        if i != id {
            //detect collisions
            if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                // Calculate the overlap or penetration depth
                let overlap: f32 = (radii[i] + radii[id]) - length(positions[i] - positions[id]);

                // Calculate the normal of collision
                let normal: vec2<f32> = normalize(positions[i] - positions[id]);

                // Calculate the force based on the overlap and the stiffness constant
                let force: vec2<f32> = stiffness * overlap * normal;

                // Apply the force to the velocities (assuming equal masses for simplicity)
                let mass1: f32 = 3.14159265 * radii[id] * radii[id];
                let mass2: f32 = 3.14159265 * radii[i] * radii[i];

                // Calculate adjusted velocities based on masses
                velocities_buf[id] = velocities_buf[id] - (2.0 * mass2 / (mass1 + mass2)) * damping * force;
            }
        }
    }

    let start = bond_info[id].x;
    let length = bond_info[id].y;
    if(start != -1){
        for(var i = u32(start); i<u32(start+length); i++){
            // let j = bonds[i];
            // let pos = positions[j];
            // let del = (radii[j] + radii[id]) - length(positions[j] - positions[id]);//positions[id] - pos;
            // let dir = normalize(pos);
            // positions[j] = positions[id] - dir * (radii[id]+radii[j]);
            // velocities_buf[j] = vec2(0.0, 0.0);//1000.0 * dir * del * deltaTime;
            // Get the bonded particle's index
            let bond_id: i32 = bonds[i];

            // Calculate the current distance between the particles
            let dist: f32 = length(positions[bond_id] - positions[id]);

            // Assuming the ideal length of the bond is the sum of radii (when they just touch each other)
            let ideal_length: f32 = radii[id] + radii[bond_id];

            // Calculate the displacement from the equilibrium position
            let displacement: f32 = ideal_length - dist;

            // Calculate the force exerted by the spring using Hooke's law
            let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(positions[bond_id] - positions[id]);

            // Apply the spring force to adjust the velocities
            let mass1: f32 = 3.14159265 * radii[id] * radii[id];
            let mass2: f32 = 3.14159265 * radii[bond_id] * radii[bond_id];

            velocities_buf[id] -= (spring_force / mass1) * damping;
            // velocities_buf[bond_id] += (spring_force / mass2) * damping; // Apply the opposite force to the bonded particle

        }
    }

    let pos = positions[id];
    let rad = radii[id];
    let elasticity = 0.5;
    let xW = 2.0*16.0/11.0;
    if pos.x+rad > xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        positions[id] = vec2(xW-rad, pos.y);
    } else if pos.x-rad < -xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        positions[id] = vec2(-xW+rad, pos.y);
    }
    if pos.y+rad > 2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        positions[id] = vec2(pos.x, 2.0-rad);
    } else if pos.y-rad < -2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        positions[id] = vec2(pos.x, -2.0+rad);
    }
}